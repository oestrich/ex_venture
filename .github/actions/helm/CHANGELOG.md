# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

### [1.6.1](https://github.com/deliverybot/helm/compare/v1.6.0...v1.6.1) (2020-06-06)


### Bug Fixes

* Remove colon in action.yml ([1f0d808](https://github.com/deliverybot/helm/commit/1f0d808b77f835b1547c80cdd5080a217465cefe))

## [1.6.0](https://github.com/deliverybot/helm/compare/v1.5.0...v1.6.0) (2020-06-06)


### Features

* Add additional parameters to download a chart by url ([#23](https://github.com/deliverybot/helm/issues/23)) ([547935f](https://github.com/deliverybot/helm/commit/547935f280af50b2cb7f7fcfd08c29f367433395))
* Add missing `helm` input parameter to action.yml ([#29](https://github.com/deliverybot/helm/issues/29)) ([8612a75](https://github.com/deliverybot/helm/commit/8612a75699d4ca8ea60072bb3350f4d26095ad27))
* Add support for EKS clusters and fix helm v3 home issue ([#27](https://github.com/deliverybot/helm/issues/27)) ([70b15cc](https://github.com/deliverybot/helm/commit/70b15cc0dc343686882dfb9185ff67cef9d47723)), closes [#22](https://github.com/deliverybot/helm/issues/22)

## [1.5.0](https://github.com/deliverybot/helm/compare/v1.4.0...v1.5.0) (2019-12-24)


### Features

* Add timeout parameter ([#18](https://github.com/deliverybot/helm/issues/18)) ([d494b05](https://github.com/deliverybot/helm/commit/d494b05))

## [1.4.0](https://github.com/deliverybot/helm/compare/v1.3.0...v1.4.0) (2019-11-21)


### Bug Fixes

* Pass kubeconfig var ([2b78a84](https://github.com/deliverybot/helm/commit/2b78a84))


### Features

* Update Helm 2 binary ([#15](https://github.com/deliverybot/helm/issues/15)) ([b5d5c58](https://github.com/deliverybot/helm/commit/b5d5c58))
* Update Helm 3 binary ([#14](https://github.com/deliverybot/helm/issues/14)) ([8dc3e86](https://github.com/deliverybot/helm/commit/8dc3e86))

## [1.3.0](https://github.com/deliverybot/helm/compare/v1.2.0...v1.3.0) (2019-10-16)


### Features

* Generated value file is last arg ([#13](https://github.com/deliverybot/helm/issues/13)) ([9e1a0cf](https://github.com/deliverybot/helm/commit/9e1a0cf))

## [1.2.0](https://github.com/deliverybot/helm/compare/v1.1.0...v1.2.0) (2019-09-30)


### Bug Fixes

* If remove mark inactive ([3edcc80](https://github.com/deliverybot/helm/commit/3edcc80))
* Include preview for inactive state ([4b47dd7](https://github.com/deliverybot/helm/commit/4b47dd7))


### Features

* Add delete --purge for helm2 ([de6b027](https://github.com/deliverybot/helm/commit/de6b027))

## [1.1.0](https://github.com/deliverybot/helm/compare/v1.0.0...v1.1.0) (2019-09-21)


### Bug Fixes

* CI pipeline using GitHub actions ([7eddfb9](https://github.com/deliverybot/helm/commit/7eddfb9))
* Helm3 compatibility on deletes ([c9eafdd](https://github.com/deliverybot/helm/commit/c9eafdd))


### Features

* Add helm3 binary ([5e2cd2f](https://github.com/deliverybot/helm/commit/5e2cd2f))
* Remove purge flag from helm delete ([3821f46](https://github.com/deliverybot/helm/commit/3821f46))

## [1.0.0](https://github.com/deliverybot/helm/compare/v0.1.2...v1.0.0) (2019-09-08)

### [0.1.2](https://github.com/deliverybot/helm/compare/v0.1.1...v0.1.2) (2019-09-08)

### [0.1.1](https://github.com/deliverybot/helm/compare/v0.1.0...v0.1.1) (2019-09-08)

## [0.1.0](https://github.com/deliverybot/helm/compare/v0.0.4...v0.1.0) (2019-09-08)


### Features

* Canary triggered on canary track only ([671da40](https://github.com/deliverybot/helm/commit/671da40))

### [0.0.4](https://github.com/deliverybot/helm/compare/v0.0.3...v0.0.4) (2019-09-08)


### Features

* Add migration ([10d3007](https://github.com/deliverybot/helm/commit/10d3007))
* Add remove canary option ([5f991c6](https://github.com/deliverybot/helm/commit/5f991c6))
* Add workers ([13efedc](https://github.com/deliverybot/helm/commit/13efedc))
* Introduce appName for canary deployments ([6538c4c](https://github.com/deliverybot/helm/commit/6538c4c))
* Update labels and names to app ([9387304](https://github.com/deliverybot/helm/commit/9387304))

### [0.0.3](https://github.com/deliverybot/helm/compare/v0.0.2...v0.0.3) (2019-09-01)


### Bug Fixes

* Add value files to args ([9036930](https://github.com/deliverybot/helm/commit/9036930))
* Default to root health ([b2d98d0](https://github.com/deliverybot/helm/commit/b2d98d0))
* Parse secret values ([64b622a](https://github.com/deliverybot/helm/commit/64b622a))
* Value list load if not string ([6483cd3](https://github.com/deliverybot/helm/commit/6483cd3))


### Features

* Helm chart customization ([abc7b15](https://github.com/deliverybot/helm/commit/abc7b15))
* Templating of value files ([4b30064](https://github.com/deliverybot/helm/commit/4b30064))

### [0.0.2](https://github.com/deliverybot/helm/compare/v0.0.1...v0.0.2) (2019-08-31)


### Bug Fixes

* Absolute path for helm chart ([e15e1e4](https://github.com/deliverybot/helm/commit/e15e1e4))
* Add debug for kubeconfig ([bfa3f4b](https://github.com/deliverybot/helm/commit/bfa3f4b))
* Add log and target url ([688f310](https://github.com/deliverybot/helm/commit/688f310))
* Cat out the value file ([4d83f1e](https://github.com/deliverybot/helm/commit/4d83f1e))
* Include debug logs about vars ([4ad9022](https://github.com/deliverybot/helm/commit/4ad9022))
* Parse values if an object ([76181ec](https://github.com/deliverybot/helm/commit/76181ec))
* Remove replace on vars ([e624622](https://github.com/deliverybot/helm/commit/e624622))
* Show variables in debug ([a416967](https://github.com/deliverybot/helm/commit/a416967))
* Undefined object opts ([ab3e5f9](https://github.com/deliverybot/helm/commit/ab3e5f9))


### Features

* Add basic app chart ([35049a2](https://github.com/deliverybot/helm/commit/35049a2))
* Add canary support built in ([27023d5](https://github.com/deliverybot/helm/commit/27023d5))

### 0.0.1 (2019-08-23)


### Features

* Add dry-run option to inputs ([988fedd](https://github.com/deliverybot/helm/commit/988fedd))
* Add helm action ([1b24336](https://github.com/deliverybot/helm/commit/1b24336))
* Add initial node_modules and package ([9005d46](https://github.com/deliverybot/helm/commit/9005d46))
* Implement deployment status ([2069c0b](https://github.com/deliverybot/helm/commit/2069c0b))
