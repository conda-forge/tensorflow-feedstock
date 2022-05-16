About libtfkernel_all_kernels
=============================

Home: http://tensorflow.org/

Package license: Apache-2.0

Feedstock license: [BSD-3-Clause](https://github.com/conda-forge/tensorflow-feedstock/blob/main/LICENSE.txt)

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
    
  <tr>
    <td>Azure</td>
    <td>
      <details>
        <summary>
          <a href="https://dev.azure.com/conda-forge/feedstock-builds/_build/latest?definitionId=4385&branchName=main">
            <img src="https://dev.azure.com/conda-forge/feedstock-builds/_apis/build/status/tensorflow-feedstock?branchName=main">
          </a>
        </summary>
        <table>
          <thead><tr><th>Variant</th><th>Status</th></tr></thead>
          <tbody><tr>
              <td>linux_64_c_compiler_version10cuda_compiler_version11.1cudnn8cxx_compiler_version10</td>
              <td>
                <a href="https://dev.azure.com/conda-forge/feedstock-builds/_build/latest?definitionId=4385&branchName=main">
                  <img src="https://dev.azure.com/conda-forge/feedstock-builds/_apis/build/status/tensorflow-feedstock?branchName=main&jobName=linux&configuration=linux_64_c_compiler_version10cuda_compiler_version11.1cudnn8cxx_compiler_version10" alt="variant">
                </a>
              </td>
            </tr><tr>
              <td>linux_64_c_compiler_version10cuda_compiler_version11.2cudnn8cxx_compiler_version10</td>
              <td>
                <a href="https://dev.azure.com/conda-forge/feedstock-builds/_build/latest?definitionId=4385&branchName=main">
                  <img src="https://dev.azure.com/conda-forge/feedstock-builds/_apis/build/status/tensorflow-feedstock?branchName=main&jobName=linux&configuration=linux_64_c_compiler_version10cuda_compiler_version11.2cudnn8cxx_compiler_version10" alt="variant">
                </a>
              </td>
            </tr><tr>
              <td>linux_64_c_compiler_version10cuda_compiler_versionNonecudnnundefinedcxx_compiler_version10</td>
              <td>
                <a href="https://dev.azure.com/conda-forge/feedstock-builds/_build/latest?definitionId=4385&branchName=main">
                  <img src="https://dev.azure.com/conda-forge/feedstock-builds/_apis/build/status/tensorflow-feedstock?branchName=main&jobName=linux&configuration=linux_64_c_compiler_version10cuda_compiler_versionNonecudnnundefinedcxx_compiler_version10" alt="variant">
                </a>
              </td>
            </tr><tr>
              <td>linux_64_c_compiler_version7cuda_compiler_version10.2cudnn7cxx_compiler_version7</td>
              <td>
                <a href="https://dev.azure.com/conda-forge/feedstock-builds/_build/latest?definitionId=4385&branchName=main">
                  <img src="https://dev.azure.com/conda-forge/feedstock-builds/_apis/build/status/tensorflow-feedstock?branchName=main&jobName=linux&configuration=linux_64_c_compiler_version7cuda_compiler_version10.2cudnn7cxx_compiler_version7" alt="variant">
                </a>
              </td>
            </tr><tr>
              <td>linux_64_c_compiler_version9cuda_compiler_version11.0cudnn8cxx_compiler_version9</td>
              <td>
                <a href="https://dev.azure.com/conda-forge/feedstock-builds/_build/latest?definitionId=4385&branchName=main">
                  <img src="https://dev.azure.com/conda-forge/feedstock-builds/_apis/build/status/tensorflow-feedstock?branchName=main&jobName=linux&configuration=linux_64_c_compiler_version9cuda_compiler_version11.0cudnn8cxx_compiler_version9" alt="variant">
                </a>
              </td>
            </tr><tr>
              <td>osx_64</td>
              <td>
                <a href="https://dev.azure.com/conda-forge/feedstock-builds/_build/latest?definitionId=4385&branchName=main">
                  <img src="https://dev.azure.com/conda-forge/feedstock-builds/_apis/build/status/tensorflow-feedstock?branchName=main&jobName=osx&configuration=osx_64_" alt="variant">
                </a>
              </td>
            </tr><tr>
              <td>osx_arm64</td>
              <td>
                <a href="https://dev.azure.com/conda-forge/feedstock-builds/_build/latest?definitionId=4385&branchName=main">
                  <img src="https://dev.azure.com/conda-forge/feedstock-builds/_apis/build/status/tensorflow-feedstock?branchName=main&jobName=osx&configuration=osx_arm64_" alt="variant">
                </a>
              </td>
            </tr>
          </tbody>
        </table>
      </details>
    </td>
  </tr>
</table>

Current release info
====================

| Name | Downloads | Version | Platforms |
| --- | --- | --- | --- |
| [![Conda Recipe](https://img.shields.io/badge/recipe-libtfkernel_all_kernels-green.svg)](https://anaconda.org/conda-forge/libtfkernel_all_kernels) | [![Conda Downloads](https://img.shields.io/conda/dn/conda-forge/libtfkernel_all_kernels.svg)](https://anaconda.org/conda-forge/libtfkernel_all_kernels) | [![Conda Version](https://img.shields.io/conda/vn/conda-forge/libtfkernel_all_kernels.svg)](https://anaconda.org/conda-forge/libtfkernel_all_kernels) | [![Conda Platforms](https://img.shields.io/conda/pn/conda-forge/libtfkernel_all_kernels.svg)](https://anaconda.org/conda-forge/libtfkernel_all_kernels) |

Installing libtfkernel_all_kernels
==================================

Installing `libtfkernel_all_kernels` from the `conda-forge` channel can be achieved by adding `conda-forge` to your channels with:

```
conda config --add channels conda-forge
conda config --set channel_priority strict
```

Once the `conda-forge` channel has been enabled, `libtfkernel_all_kernels` can be installed with `conda`:

```
conda install libtfkernel_all_kernels
```

or with `mamba`:

```
mamba install libtfkernel_all_kernels
```

It is possible to list all of the versions of `libtfkernel_all_kernels` available on your platform with `conda`:

```
conda search libtfkernel_all_kernels --channel conda-forge
```

or with `mamba`:

```
mamba search libtfkernel_all_kernels --channel conda-forge
```

Alternatively, `mamba repoquery` may provide more information:

```
# Search all versions available on your platform:
mamba repoquery search libtfkernel_all_kernels --channel conda-forge

# List packages depending on `libtfkernel_all_kernels`:
mamba repoquery whoneeds libtfkernel_all_kernels --channel conda-forge

# List dependencies of `libtfkernel_all_kernels`:
mamba repoquery depends libtfkernel_all_kernels --channel conda-forge
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
[conda-forge](https://anaconda.org/conda-forge) [Anaconda-Cloud](https://anaconda.org/)
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


Updating libtfkernel_all_kernels-feedstock
==========================================

If you would like to improve the libtfkernel_all_kernels recipe or build a new
package version, please fork this repository and submit a PR. Upon submission,
your changes will be run on the appropriate platforms to give the reviewer an
opportunity to confirm that the changes result in a successful build. Once
merged, the recipe will be re-built and uploaded automatically to the
`conda-forge` channel, whereupon the built conda packages will be available for
everybody to install and use from the `conda-forge` channel.
Note that all branches in the conda-forge/libtfkernel_all_kernels-feedstock are
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

* [@conda-forge/tensorflow](https://github.com/conda-forge/tensorflow/)

