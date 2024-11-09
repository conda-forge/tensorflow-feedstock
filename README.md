About tensorflow-feedstock
==========================

Feedstock license: [BSD-3-Clause](https://github.com/conda-forge/tensorflow-feedstock/blob/main/LICENSE.txt)

Home: http://tensorflow.org/

Package license: Apache-2.0

Summary: TensorFlow is an end-to-end open source platform for machine learning.

Development: https://github.com/tensorflow/tensorflow

Documentation: https://www.tensorflow.org/get_started/get_started

TensorFlow offers multiple levels of abstraction so you can choose the
right one for your needs. Build and train models by using the high-level
Keras API, which makes getting started with TensorFlow and machine learning
easy.


Current build status
====================


<table>
</table>

Current release info
====================

| Name | Downloads | Version | Platforms |
| --- | --- | --- | --- |
| [![Conda Recipe](https://img.shields.io/badge/recipe-libtensorflow-green.svg)](https://anaconda.org/conda-forge/libtensorflow) | [![Conda Downloads](https://img.shields.io/conda/dn/conda-forge/libtensorflow.svg)](https://anaconda.org/conda-forge/libtensorflow) | [![Conda Version](https://img.shields.io/conda/vn/conda-forge/libtensorflow.svg)](https://anaconda.org/conda-forge/libtensorflow) | [![Conda Platforms](https://img.shields.io/conda/pn/conda-forge/libtensorflow.svg)](https://anaconda.org/conda-forge/libtensorflow) |
| [![Conda Recipe](https://img.shields.io/badge/recipe-libtensorflow_cc-green.svg)](https://anaconda.org/conda-forge/libtensorflow_cc) | [![Conda Downloads](https://img.shields.io/conda/dn/conda-forge/libtensorflow_cc.svg)](https://anaconda.org/conda-forge/libtensorflow_cc) | [![Conda Version](https://img.shields.io/conda/vn/conda-forge/libtensorflow_cc.svg)](https://anaconda.org/conda-forge/libtensorflow_cc) | [![Conda Platforms](https://img.shields.io/conda/pn/conda-forge/libtensorflow_cc.svg)](https://anaconda.org/conda-forge/libtensorflow_cc) |
| [![Conda Recipe](https://img.shields.io/badge/recipe-tensorflow-green.svg)](https://anaconda.org/conda-forge/tensorflow) | [![Conda Downloads](https://img.shields.io/conda/dn/conda-forge/tensorflow.svg)](https://anaconda.org/conda-forge/tensorflow) | [![Conda Version](https://img.shields.io/conda/vn/conda-forge/tensorflow.svg)](https://anaconda.org/conda-forge/tensorflow) | [![Conda Platforms](https://img.shields.io/conda/pn/conda-forge/tensorflow.svg)](https://anaconda.org/conda-forge/tensorflow) |
| [![Conda Recipe](https://img.shields.io/badge/recipe-tensorflow--base-green.svg)](https://anaconda.org/conda-forge/tensorflow-base) | [![Conda Downloads](https://img.shields.io/conda/dn/conda-forge/tensorflow-base.svg)](https://anaconda.org/conda-forge/tensorflow-base) | [![Conda Version](https://img.shields.io/conda/vn/conda-forge/tensorflow-base.svg)](https://anaconda.org/conda-forge/tensorflow-base) | [![Conda Platforms](https://img.shields.io/conda/pn/conda-forge/tensorflow-base.svg)](https://anaconda.org/conda-forge/tensorflow-base) |
| [![Conda Recipe](https://img.shields.io/badge/recipe-tensorflow--estimator-green.svg)](https://anaconda.org/conda-forge/tensorflow-estimator) | [![Conda Downloads](https://img.shields.io/conda/dn/conda-forge/tensorflow-estimator.svg)](https://anaconda.org/conda-forge/tensorflow-estimator) | [![Conda Version](https://img.shields.io/conda/vn/conda-forge/tensorflow-estimator.svg)](https://anaconda.org/conda-forge/tensorflow-estimator) | [![Conda Platforms](https://img.shields.io/conda/pn/conda-forge/tensorflow-estimator.svg)](https://anaconda.org/conda-forge/tensorflow-estimator) |
| [![Conda Recipe](https://img.shields.io/badge/recipe-tensorflow--gpu-green.svg)](https://anaconda.org/conda-forge/tensorflow-gpu) | [![Conda Downloads](https://img.shields.io/conda/dn/conda-forge/tensorflow-gpu.svg)](https://anaconda.org/conda-forge/tensorflow-gpu) | [![Conda Version](https://img.shields.io/conda/vn/conda-forge/tensorflow-gpu.svg)](https://anaconda.org/conda-forge/tensorflow-gpu) | [![Conda Platforms](https://img.shields.io/conda/pn/conda-forge/tensorflow-gpu.svg)](https://anaconda.org/conda-forge/tensorflow-gpu) |

Installing tensorflow
=====================

Installing `tensorflow` from the `conda-forge` channel can be achieved by adding `conda-forge` to your channels with:

```
conda config --add channels conda-forge
conda config --set channel_priority strict
```

Once the `conda-forge` channel has been enabled, `libtensorflow, libtensorflow_cc, tensorflow, tensorflow-base, tensorflow-estimator, tensorflow-gpu` can be installed with `conda`:

```
conda install libtensorflow libtensorflow_cc tensorflow tensorflow-base tensorflow-estimator tensorflow-gpu
```

or with `mamba`:

```
mamba install libtensorflow libtensorflow_cc tensorflow tensorflow-base tensorflow-estimator tensorflow-gpu
```

It is possible to list all of the versions of `libtensorflow` available on your platform with `conda`:

```
conda search libtensorflow --channel conda-forge
```

or with `mamba`:

```
mamba search libtensorflow --channel conda-forge
```

Alternatively, `mamba repoquery` may provide more information:

```
# Search all versions available on your platform:
mamba repoquery search libtensorflow --channel conda-forge

# List packages depending on `libtensorflow`:
mamba repoquery whoneeds libtensorflow --channel conda-forge

# List dependencies of `libtensorflow`:
mamba repoquery depends libtensorflow --channel conda-forge
```


About conda-forge
=================

[![Powered by
NumFOCUS](https://img.shields.io/badge/powered%20by-NumFOCUS-orange.svg?style=flat&colorA=E1523D&colorB=007D8A)](https://numfocus.org)

conda-forge is a community-led conda channel of installable packages.
In order to provide high-quality builds, the process has been automated into the
conda-forge GitHub organization. The conda-forge organization contains one repository
for each of the installable packages. Such a repository is known as a *feedstock*.

A feedstock is made up of a conda recipe (the instructions on what and how to build
the package) and the necessary configurations for automatic building using freely
available continuous integration services. Thanks to the awesome service provided by
[Azure](https://azure.microsoft.com/en-us/services/devops/), [GitHub](https://github.com/),
[CircleCI](https://circleci.com/), [AppVeyor](https://www.appveyor.com/),
[Drone](https://cloud.drone.io/welcome), and [TravisCI](https://travis-ci.com/)
it is possible to build and upload installable packages to the
[conda-forge](https://anaconda.org/conda-forge) [anaconda.org](https://anaconda.org/)
channel for Linux, Windows and OSX respectively.

To manage the continuous integration and simplify feedstock maintenance
[conda-smithy](https://github.com/conda-forge/conda-smithy) has been developed.
Using the ``conda-forge.yml`` within this repository, it is possible to re-render all of
this feedstock's supporting files (e.g. the CI configuration files) with ``conda smithy rerender``.

For more information please check the [conda-forge documentation](https://conda-forge.org/docs/).

Terminology
===========

**feedstock** - the conda recipe (raw material), supporting scripts and CI configuration.

**conda-smithy** - the tool which helps orchestrate the feedstock.
                   Its primary use is in the construction of the CI ``.yml`` files
                   and simplify the management of *many* feedstocks.

**conda-forge** - the place where the feedstock and smithy live and work to
                  produce the finished article (built conda distributions)


Updating tensorflow-feedstock
=============================

If you would like to improve the tensorflow recipe or build a new
package version, please fork this repository and submit a PR. Upon submission,
your changes will be run on the appropriate platforms to give the reviewer an
opportunity to confirm that the changes result in a successful build. Once
merged, the recipe will be re-built and uploaded automatically to the
`conda-forge` channel, whereupon the built conda packages will be available for
everybody to install and use from the `conda-forge` channel.
Note that all branches in the conda-forge/tensorflow-feedstock are
immediately built and any created packages are uploaded, so PRs should be based
on branches in forks and branches in the main repository should only be used to
build distinct package versions.

In order to produce a uniquely identifiable distribution:
 * If the version of a package **is not** being increased, please add or increase
   the [``build/number``](https://docs.conda.io/projects/conda-build/en/latest/resources/define-metadata.html#build-number-and-string).
 * If the version of a package **is** being increased, please remember to return
   the [``build/number``](https://docs.conda.io/projects/conda-build/en/latest/resources/define-metadata.html#build-number-and-string)
   back to 0.

Feedstock Maintainers
=====================

* [@farhantejani](https://github.com/farhantejani/)
* [@ghego](https://github.com/ghego/)
* [@h-vetinari](https://github.com/h-vetinari/)
* [@hajapy](https://github.com/hajapy/)
* [@hmaarrfk](https://github.com/hmaarrfk/)
* [@jschueller](https://github.com/jschueller/)
* [@ngam](https://github.com/ngam/)
* [@njzjz](https://github.com/njzjz/)
* [@waitingkuo](https://github.com/waitingkuo/)
* [@wolfv](https://github.com/wolfv/)
* [@xhochy](https://github.com/xhochy/)

