# analytics-platform-rstudio

RStudio Docker image for Analytics Platform. Used by [RStudio helm chart](https://github.com/ministryofjustice/analytics-platform-helm-charts/tree/master/charts/rstudio).

**NB Changes in this repo are public**
This work is done in an [internal repo](https://github.com/ministryofjustice/analytics-platform-rstudio) and immediately sync'ed to a [public copy](https://github.com/ministryofjustice/analytics-platform-rstudio-public). This allows the [sensitive CI/CD](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners#self-hosted-runner-security-with-public-repositories) to run in private, but to maintain our commitment to [code in the open](https://www.gov.uk/service-manual/service-standard/point-12-make-new-source-code-open). [Further info](https://docs.google.com/document/d/1BGyHttQa3wI-UsdCBqu-398yZRhnjCuldHHgwTVaJSg/edit)

## Builds

The docker image is built using GitHub Actions and hosted on an internal ECR repository.

## Usage

To add/remove R packages to this image, edit the `R_packages` file accordingly then build the image remembering to
update the tag

### Build

```bash
make build
```

### Run locally

```bash
make up
```

## Design discussion

* Rocker is the standard Docker image for R
* We choose "verse" variant (because we want TinyTeX)
* Install Conda, because that is our recommended package manager
* Install a few system packages needed by analysts, which really can't be installed by user with Conda (minimize these as they bloat everyone)

### Users

The rocker image creates 'rstudio' user (uid 1000) for [normal user use](https://www.rocker-project.org/use/managing_users/#custom-usernames-and-user-ids). However AP's Dockerfile [introduces another user](https://github.com/ministryofjustice/analytics-platform-rstudio/commit/46527fd018e0f105e797fa7b92b962ff0e4cee27), named after the user's GitHub username (uid 1001). We're not entirely sure.

There are a couple of consequences of using uid 1001:

* **slow chown** - Rocker [creates the home directory with ownership by 'rstudio' (1000)](https://github.com/rocker-org/rocker-versioned/blob/master/rstudio/3.5.1.Dockerfile#L55-L60). So AP needs to 'chown' it to 1001, otherwise users don't have permissions to the home dir. Once the home dir is full of files, the chown takes a while, slowing startup of RStudio.

* **affects other tools** - The [Jupyter image also has to use 1001 and do the chown](https://github.com/ministryofjustice/analytics-platform-jupyter-notebook/blob/95c830dd6ff726c7831a227a247fd6cc869d8dee/datascience-notebook/Dockerfile#L20-L22), because it shares the home directory.

So maybe we could switch to just using the rstudio/1000 user?
