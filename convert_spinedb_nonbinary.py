import os
from pathlib import Path
import spinedb_api as api
import json
import toml
import yaml
from rdflib import Graph, Namespace, URIRef, RDF, RDFS, Literal, BNode, OWL

filedirectory = Path(__file__).parent.resolve()
os.chdir(filedirectory)
spinepath = "sqlite:///ines-spec.sqlite"
jsonpath = "ines-spec.json"
yamlpath = "ines-spec.yaml"
tomlpath = "ines-spec.toml"

with api.DatabaseMapping(spinepath) as db_map:
    fulldata = api.export_data(db_map,parse_value=api.parameter_value.load_db_value)
    data = {
        k:fulldata[k] for k in [
            "entity_classes",
            "parameter_value_lists",
            "parameter_definitions"
        ]
    }
    with open(jsonpath, 'w') as f:
        json.dump(data, f, indent=4)
    g = Graph()
    ines = Namespace("ines-spec:")
    g.bind("ines", ines)
    g.bind("owl", OWL)

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
        class_namespace = Namespace(str(ines) + param_def[0] + ":")
        has_param = URIRef(class_namespace + param_def[1])
        class_of_param = URIRef(ines + param_def[0])
        g.add((has_param, RDF.type, OWL.DatatypeProperty))
        g.add((has_param, RDFS.domain, class_of_param))
        g.add((has_param, RDFS.range, RDFS.Literal))  # Range is literal value
        g.add((has_param, RDFS.comment, Literal(param_def[4])))
    g.serialize(destination="ines-spec.ttl")

# the direct conversion from spinedb to yaml causes problems so the conversion is done indirectly through json
with open(jsonpath, 'r') as f:
    data = json.load(f)
    with open(yamlpath, 'w') as f:
        yaml.dump(data, f)
    with open(tomlpath, 'w') as f:
        toml.dump(data, f, encoder=toml.TomlEncoder())
