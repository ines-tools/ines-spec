> [!IMPORTANT]
> Git branching strategy has been changed (19.12.2024). Main branch is ditched and replaced by branch v0.x. The next branch with major breaking changes is v1.x. One can already start using it, but it will still be modified in small ways. As ines-spec is used mainly by conversion tools that depend on specific data structures, we are taking an explicit approach to the choice of the version to be used.

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
