Summary [![Build Status](https://travis-ci.org/UBC-Stat-ML/blangSDK.png?branch=master)](https://travis-ci.org/UBC-Stat-ML/blangSDK) 
-------

**Prospective/current users**: please vist the [project web page](https://www.stat.ubc.ca/~bouchard/blang/index.html) for more information.

**Blang developers**: in addition to the above resources, see also the [documentation repository](https://github.com/UBC-Stat-ML/blangDoc) for more information.

This is one of the repositories hosting Blang's code. This one contains the Blang's SDK (Software Development Kit), including:

- Basic datatypes suitable for sampling such as ``Real``, ``Int``, ``Simplex``, etc.
- Infrastructure to create new data types and distributions.
- Inference algorithms for such datatypes, such as [Adaptive Non-Reversible Parallel Tempering](https://www.stat.ubc.ca/~bouchard/pub/Syed2019NRPT.pdf) and Sequential Change of Measure.
- Standard probability distributions.
- MCMC testing infrastructure.
- Runtime to perform static analysis to infer the factor graph and its sparsity patterns. 
- Automated post-processing facilities (MCMC diagnostic, trace/density/pmf/summaries generation, etc).

See [this readme](https://github.com/UBC-Stat-ML/blangDoc/blob/master/README.md) for a roadmap of the other key repositories (language infrastructure, examples, supporting libraries, etc)




