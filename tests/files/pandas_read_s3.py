import pandas as pd

csv = pd.read_csv("s3://inspec.test.docker.rstudio/test.csv")

print(csv)
