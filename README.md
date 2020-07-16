# analytics-platform-rstudio

RStudio Docker image for Analytics Platform. Used by [RStudio helm chart](https://github.com/ministryofjustice/analytics-platform-helm-charts/tree/master/charts/rstudio).

[![Docker Repository on Quay](https://quay.io/repository/mojanalytics/rstudio/status "Docker Repository on Quay")](https://quay.io/repository/mojanalytics/rstudio)

## Builds

The docker image is built and hosted on [Quay.io](https://quay.io/repository/mojanalytics/rstudio)

## Usage

To add/remove R packages to this image, edit the `R_packages` file accordingly then build the image remembering to
update the tag

### Build

```bash
docker image build --no-cache -t quay.io/mojanalytics/rstudio .
```

#### Run locally

```bash
docker container run -d --rm -p 8787:8787 quay.io/mojanalytics/rstudio
```

#### Tag/Push

When satisfied Tag and push the image

Tag

```bash
docker image tag quay.io/mojanalytics/rstudio quay.io/mojanalytics/rstudio:<x.x.x>
```

Push

```bash
docker image push quay.io/mojanalytics/rstudio:<x.x.x>
```

## Tricks

### Find apt package with a certain file

RStudio may complain about some missing file. There is a command to find
the package containing the file:

```bash
apt-get install apt-file
apt-file update
apt-file search titling.sty
```

See: <https://github.com/rstudio/rmarkdown/issues/359#issuecomment-253335365>
