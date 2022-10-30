# Common Infra Jenkins

This project aims to have a manageable Jenkins server that is configurable as code.
It also aims to have a scalable pipeline by utilizing cloud services as Jenkins agent.

## Getting Started

### Prerequisites

- Nodejs
- Docker

### Shared Libraries

The information for shared libraries used by the jenkins instance can be found [here](https://github.com/devhalos/common-infra-jenkins-libs)

### Job DSL Plugin

Api documentation can be viewed in

```
{jenkins-base-url}/job-dsl/api-viewer/index.html
```

### Initialize Project

Install npm dependencies. It is required for git message linting and for generating changelog for release.

```shell
npm i
```  

## Running the tests

```shell
npm test
```

### Build Image

Follow [semver](https://semver.org/) convention for naming the image tag

#### Development


```shell
npm run build {image-tag} .
npm run build 0.0.1-alpha .
npm run build 0.0.1 .
```

#### Production
```shell
npm run build {next-version} .
```

## Deployment

### Local Deployment

#### Prepare

- Build image. See [Build](#build) section
- Set environment variables required for the deployment.
    1. Copy ./dev/.env to ./.env. It contains the list of env vars without value
    2. Populate values of the env vars in ./.env file

#### Deploy

```shell
npm run build:deploy:dev
```

### Deploy in ECS

TBD

### Generating Changelog for Release

We use [standard-version](https://github.com/conventional-changelog/standard-version) to generate release changelog. The changelog will use the commit messages, so the format must confirm to [Conventional Commit](https://www.conventionalcommits.org/en/v1.0.0/).

```shell
# update version base on the commit messages after the previous release
npm run release 

# update patch version, e.g from 1.0.0 to 1.0.1
# use only for bug fixes that introduce no breaking changes
npm run release:patch 

# update minor version, e.g from 1.0.0 to 1.1.0
# for new features that do not introduce breaking changes
npm run release:minor 

# update major version, e.g from 1.0.0 to 2.0.0
# for new features/bug fixes that introduce breaking changes
npm run release:major
```

## Built With

* [Nodejs](https://nodejs.org/en/) - Use for git commit linting and changelog generation
* [Docker](https://www.docker.com/) - Use for creating container for deployment

## Contributing

Please read [CONTRIBUTING.md](https://gist.github.com/PurpleBooth/b24679402957c63ec426) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags).

## Authors

* **Jayson Ojeda** - *Initial work* - [Nihil Project](https://devhalos.atlassian.net/wiki/spaces/NIH)

See also the list of [contributors](https://github.com/your/project/contributors) who participated in this project.

## License

This project is licensed under the GNU GENERAL PUBLIC LICENSE version 3 - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

TBD

