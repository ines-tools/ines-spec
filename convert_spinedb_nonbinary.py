import os
from pathlib import Path
import spinedb_api as api
import json
import toml
import yaml
import csv
from rdflib import Graph, Namespace, URIRef, RDF, RDFS, Literal, BNode, OWL

filedirectory = Path(__file__).parent.resolve()
os.chdir(filedirectory)
spinepath = "sqlite:///ines-spec.sqlite"
jsonpath = "ines-spec.json"
yamlpath = "ines-spec.yaml"
tomlpath = "ines-spec.toml"


class MultilineTomlEncoder(toml.TomlEncoder):
    """
    Custom TOML encoder that formats nested lists with each item on a separate line,
    but keeps the inner list elements on a single line.
    """

    def __init__(self, _dict=dict, preserve=False):
        super().__init__(_dict, preserve)

    def dump_list(self, v):
        if not v:
            return "[]"

        # Handle lists of lists (put each sublist on its own line)
        if any(isinstance(item, list) for item in v):
            retval = "[\n"
            for item in v:
                if isinstance(item, list):
                    # Convert inner list to string manually to avoid encoding issues
                    inner_items = []
                    for x in item:
                        if isinstance(x, str):
                            # Properly handle string values
                            inner_items.append(f'"{x}"')
                        elif isinstance(x, bool):
                            # Properly handle boolean values
                            inner_items.append(str(x).lower())
                        else:
                            # Handle numbers and other types
                            inner_items.append(str(x))

                    inner_list = "[" + ", ".join(inner_items) + "]"
                    retval += f"    {inner_list},\n"
                else:
                    # For non-list items
                    retval += f"    {self.dump_value(item)},\n"

            # Remove trailing comma if present
            if retval.endswith(",\n"):
                retval = retval[:-2] + "\n"

            return retval + "]"

        # For simple lists (not containing other lists)
        return super().dump_list(v)


with api.DatabaseMapping(spinepath) as db_map:
    fulldata = api.export_data(db_map,parse_value=api.parameter_value.load_db_value)
    data = {
        k:fulldata[k] for k in [
            "entity_classes",
            "parameter_value_lists",
            "parameter_definitions",
            "parameter_types",
            "superclass_subclasses"
        ]
    }
    with open(jsonpath, 'w') as f:
        json.dump(data, f, indent=4)
    g = Graph()
    ines = Namespace("ines-spec#")
    SCHEMA = Namespace("http://schema.org/")
    g.bind("ines", ines)
    g.bind("owl", OWL)
    #g.bind("schema", SCHEMA)


    for entity_class in fulldata["entity_classes"]:
        if not entity_class[1]:
            class_uri = getattr(ines, entity_class[0])
            g.add((class_uri, RDF.type, OWL.Class))
            #g.add((class_uri, RDFS.label, Literal(entity_class[0])))
        else:
            nd_class_uri = getattr(ines, entity_class[0])
            g.add((nd_class_uri, RDF.type, OWL.Class))
            for base_class_name in entity_class[1]:
                base_class = getattr(ines, base_class_name)
                has_base_class = getattr(ines, "has_" + base_class_name)
                g.add((has_base_class, RDF.type, OWL.ObjectProperty))
                g.add((has_base_class, RDFS.range, base_class))
                class_restriction = BNode()
                g.add((class_restriction, RDF.type, OWL.Restriction))
                g.add((class_restriction, OWL.onProperty, has_base_class))
                g.add((class_restriction, OWL.cardinality, Literal(1)))
                g.add((nd_class_uri, RDFS.subClassOf, class_restriction))
                #g.add((has_base_class, RDF.type, OWL.ObjectProperty))
                #g.add((has_base_class, RDFS.domain, nd_class_uri))
                #g.add((has_base_class, RDFS.range, base_class))

    for param_def in fulldata["parameter_definitions"]:
        has_param = ines[f"{param_def[0]}.{param_def[1]}"]
        g.add((has_param, RDF.type, OWL.DatatypeProperty))
        g.add((has_param, SCHEMA.domainIncludes, ines[param_def[0]]))
        #g.add((has_param, RDFS.domain, ines[param_def[0]]))
        g.add((has_param, RDFS.range, RDFS.Literal))  # Range is literal value
        g.add((has_param, RDFS.comment, Literal(param_def[4])))
    g.serialize(destination="ines-spec.ttl", format="turtle")

# the direct conversion from spinedb to yaml causes problems so the conversion is done indirectly through json
with open(jsonpath, 'r') as json_f:
    data = json.load(json_f)
    with open(yamlpath, 'w') as yaml_f:
        yaml.dump(data, yaml_f)
    with open(tomlpath, 'w') as toml_f:
        toml.dump(data, toml_f, encoder=MultilineTomlEncoder())
    with open("ines-spec-entity-classes.csv", "w", newline="") as csv_f:
        writer = csv.writer(csv_f)
        writer.writerow(["'class name'","dimensions","description","symbol","'active by default'"])
        writer.writerows(data["entity_classes"])
    with open("ines-spec-parameter-definitions.csv", "w", newline="") as csv_f:
        writer = csv.writer(csv_f)
        writer.writerow(["'class name'","'parameter name'","'valid types'","'value list name'","description"])
        writer.writerows(data["parameter_definitions"])
    with open("ines-spec-parameter-value-lists.csv", "w", newline="") as csv_f:
        writer = csv.writer(csv_f)
        writer.writerow(["'parameter name'","'list member name'"])
        writer.writerows(data["parameter_value_lists"])


print ("Done writing out ines-spec to json, yaml, toml, csv and ttl")
