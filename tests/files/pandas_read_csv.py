"""Check that Pandas can read the shared CSV fixture."""

import pandas as pd

csv = pd.read_csv("/share/tests/files/test.csv")

print(csv)
