# IDL-UCRio

![Stable version](https://img.shields.io/badge/Latest%20stable%20release-v1.0.0-orange)
![IDL version required](https://img.shields.io/badge/IDL-8.8.3%2B-blue)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.14239005.svg)](https://doi.org/10.5281/zenodo.14239005)

IDL-UCRio is an IDL library providing data access and analysis support for RF instrument data provided by the University of Calgary. This presently includes the NORSTAR riometers, and the SWAN Hyper Spectral Riometers (HSR).

IDL-UCRio officially supports IDL 8.8.3+.

Some links to help:
- [Example Gallery](https://data.phys.ucalgary.ca/working_with_data/index.html#idl)
- [UCalgary SRS Open Data Platform](https://data.phys.ucalgary.ca)
- [Additional examples](https://github.com/ucalgary-srs/idl-ucrio/tree/main/src/examples)
- [Browse releases](https://github.com/ucalgary-srs/idl-ucrio/releases)

## Usage

For usage details, please explore the crib sheets available at the UCalgary SRS Open Data Platform website. Further, you can view the examples in this repository. See links below.

- [UCalgary SRS Open Data Platform - IDL crib sheets](https://data.phys.ucalgary.ca/working_with_data/index.html#idl)
- [Examples in repository](https://github.com/ucalgary-srs/idl-ucrio/tree/main/src/examples)

## Installation

Installation can be done two different ways:

1) using the `ipm` command (recommended), or 
2) manually adding the files to your IDL path.

### Using ipm (recommended)

Since IDL 8.7.1, there exists an IDL package manager called [ipm](https://www.l3harrisgeospatial.com/docs/ipm.html#INSTALL). We can use this to install the IDL-UCRio library with a single command. This is the recommended way of installing the library.

1. From the IDL command prompt, run the following:

    ```idl
    IDL> ipm,/install,'https://data.phys.ucalgary.ca/software-releases/idl-ucrio/latest.zip'
    ```

2. Add the following to your startup file, or run the command manually using the IDL command prompt.

    ```
    [ open your startup.pro file and put the following in it ]
    @ucrio_startup
    ```

3. [OPTIONAL] If you added the above line to your startup file, you must reset your IDL session. Do this by either clicking the Reset button in the IDL editor or by typing `.reset` into the IDL command prompt.

For further information, you can view what packages are installed using `ipm,/list`. You can also view the package details using `ipm,/query,'idl-ucrio'`.

### Manually

Alternatively, you can install the idl-ucrio library manually by downloading the ZIP file and extracting it into, or adding it to, your IDL path. 

1. Download the latest release [here](https://https://data.phys.ucalgary.ca/software-releases/idl-ucrio/latest.zip). Or browse previous releases [here](https://data.phys.ucalgary.ca/software-releases/idl-ucrio).
2. Extract the zip file into your IDL path (or add it as a directory to your IDL path)
3. Add the following to your startup file (or run the command manually using the IDL command prompt).

    ```
    [ open your startup.pro file and put the following in it ]
    @ucrio_startup
    ```

4. [OPTIONAL] If you added the above line to your startup file, you must reset your IDL session. Do this by either clicking the Reset button in the IDL editor or by typing `.reset` into the IDL command prompt.

## Updating

If you used `ipm` to install idl-ucrio, you can update it using:

```idl
IDL> ipm,/update,'idl-ucrio'
IDL> .full_reset

; if not in your startup file, run this:
IDL> @ucrio_startup
```

If you installed the code manually, you can download the latest Zip file and overwrite the existing files. Then, add any new `.run` commands to your startup file as defined in the "Installation" section above.
