import shutil
from typing import Tuple

import texttable

from ossaudit import audit, packages


def custom_cli(
        file_name: str,
        columns: Tuple[str] = ['name', 'version', 'title'],
        ignore_ids: Tuple[str] = [],
) -> None:
    with open(file_name, 'r') as f:
        file_list = [f]
        pkgs = []  # type: list
        pkgs += packages.get_from_files(file_list)

    vulns = [
        v for v in audit.components(pkgs=pkgs)
        if v.id not in ignore_ids and v.cve not in ignore_ids
    ]

    response = ""
    if vulns:
        size = shutil.get_terminal_size()
        table = texttable.Texttable(max_width=size.columns)
        table.header(columns)
        table.set_cols_dtype(["t" for _ in range(len(columns))])
        table.add_rows([[getattr(v, c.lower(), "")
                         for c in columns]
                        for v in vulns], False)
        response += table.draw() + '\n'

    vlen, plen = len(vulns), len(pkgs)
    response += "Found {} vulnerabilities in {} packages".format(vlen, plen)
    return response

if __name__ == "__main__":
    resp = custom_cli(file_name=['requirements.txt'])
    if "Found 0" in resp:
        print("No vulnerabilities found")
    else:
        print(resp)