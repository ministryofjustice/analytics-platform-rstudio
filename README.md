# analytics-platform-rstudio

RStudio Docker image for Analytics Platform

[![Docker Repository on Quay](https://quay.io/repository/mojanalytics/rstudio/status "Docker Repository on Quay")](https://quay.io/repository/mojanalytics/rstudio)

**IMPORTANT**: RStudio Server **authentication is disabled**.
Do not run this image on the internet unless you secure it properly
with an Auth Proxy in front of it.
As authentication is disabled, RStudio Server needs to know which
user is accessing RStudio, so you need to set the `USER` environment
variable.


## Usage

To add/remove R packages to this image? Edit the `R_packages` file accordingly then build the image remembering to
update the tag

#### Build
```
docker image build --no-cache -t quay.io/mojanalytics/rstudio .
```

#### Run locally
```
docker container run -d --rm -p 8787:8787 quay.io/mojanalytics/rstudio
```

#### Tag/Push
When satisfied Tag and push the image

Tag
```
docker image tag quay.io/mojanalytics/rstudio quay.io/mojanalytics/rstudio:<x.x.x>
```

Push
```
docker image push quay.io/mojanalytics/rstudio:<x.x.x>
```

## Tricks

### Find apt package with a certain file

RStudio may complain about some missing file. There is a command to find
the package containing the file:

```bash
$ apt-get install apt-file
$ apt-file update
$ apt-file search titling.sty
```

See: https://github.com/rstudio/rmarkdown/issues/359#issuecomment-253335365
