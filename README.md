# INES Specification (ines-spec)

The INES (Interoperable Energy System) Specification defines a standardized data format for exchanging energy system models. This specification aims to facilitate interoperability between different energy modeling tools and platforms.

## Overview

The INES Specification is designed to support the seamless exchange of energy system data. It is currently hosted by the Spine Toolbox database file `ines-spec.sqlite` and requires Spine Toolbox v0.8 or later. The specification is also available in JSON and YAML formats for faster access.

## Features

- **Interoperability**: Enables the exchange of data between various energy modeling tools.
- **Flexibility**: Supports complex parameter structures and alternative parameter values to facilitate scenario building.
- **Compatibility**: Compatible with Spine Toolbox v0.8 and later versions.

## Installation

To use the INES Specification, you need to have Spine Toolbox v0.8 or later installed. You can download Spine Toolbox from the official [Spine Toolbox repository](https://github.com/spine-tools/Spine-Toolbox).

## Usage

- **Edit data yourself** Use Spine Toolbox database editor to add and edit data
- **Transform existing model data to ines** Use one of the adjacent repositories (e.g. ines-osemosys) to translate an existing energy system model to the ines format
- **Transform ines data to energy system model format** Use one of the adjacent repositories (e.g. ines-flextool) to translate data from the ines format to an existing energy system model format
- **Use data pipelines** The adjacent repository data-pipelines has scripts and data sources that can be imported to ines-spec to create a model instance

## Structural notes

### Main physical entities are nodes, units, and links

- Storages are special nodes (nodes that have a state)
- Commodities are also special nodes (nodes that do not have a balance constraint, but have a price).
- Units and links are quite similar - they could be grouped into one, but they are kept separate to allow better organisation of energy system model data.
The intention is that units convert energy (or material) while links transfer. Transfer links are often two-way, but not necessarily. Similarly, units are typically one-way,
but two-way option is available.
- Links connect always two nodes. The connections are represented by node__link__node entity.
- It is possible to define both directions: nodeA__link__nodeB and nodeB__link__nodeA. This enables giving separate parameter values to both directions (e.g. 'capacity'). 
If only one of these is defined, then given parameter values apply to both directions.
- Units can have none, one or multiple inputs and/or outputs.
- Inputs are defined through node__to_unit and outputs through unit__to_node. Both of these belong to the superclass unit_flow (automatically).
- The superclass unit_flow is used to build unit_flow__unit_flow entities that allow to set arbitrary constraints between two flows.

### Solve structures

- The solve_pattern entities define how to solve model over time. It enables operational rolling solves as well as multi-year investment solves.
- The 'includes_solve_pattern' parameter can be used to create nested solve structures.
- **Always needed**: solve_pattern --> period

### Temporal structures

- System entity has a parameter 'timeline' that defines the timesteps that can be present in a model instance. Allows to domain check the input data.
- The timesteps defined in the timeline can then be used across multiple time relevant parameters.
- The timesteps need to be expressed in ISO standard datetime
- Timeline often uses historical datetimes, since profile like information is typically sourced from the past.
- Period class is used to define data that refers to longer timespans - typically a year. Period data usually concern future (unless backcasting).
- Temporality class can be used to define a time resolution for a portion of the model

### Sets define shared constraints

- Sets are used to set constraints on a group of flows, capacities or emissions. They can be cumulative, period-wise or instantenous (apply to each timestep). 
- Sets are also used to indicate what belong together, for example to the same grid.

### Constraints allow to define user-defined restrictions

- Constraint entity sets the sense and optional constant for a user-defined constraint equation
- Flows, nodes, quantities, and online variables can be connected to the constraint by using respective constraint_..._coefficient parametiers

### Unit, node and link capacities

- Units and links are invested in and turned on/off on per unit basis. Consequently, every unit/link needs to have capacity of one unit defined. 
For units, the capacity is defined for each unit_flow. If unit has one input or one output, it can be sufficient to define capacity only for that
(but with multiple inputs/outputs, care has to be taken to define a valid operating area). Links and nodes have capacity defined on the link/node entity,
but links can redefine the capacity through node__link__node if the two directions differ.
- In order to unequivocally define something to be invested in, there needs to be investment_cost and capacity defined.

## Contributing

We welcome contributions to the INES Specification. Please follow these steps to contribute:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature-branch`).
3. Make your changes.
4. Commit your changes (`git commit -m 'Add new feature'`).
5. Push to the branch (`git push origin feature-branch`).
6. Create a new Pull Request.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Contact

For questions or support, please open an issue in the repository or contact the maintainers.
