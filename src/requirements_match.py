import re

def is_requirements_format(string: str) -> bool:
    # Define the regular expression pattern for requirements.txt entries
    pattern = r"""
    ^\s*  # Allow leading whitespace
    (     # Start of main capturing group
        # Package name with optional version specifier
        (?P<package>[a-zA-Z0-9._-]+)  # Package name
        (?:  # Version specifier (non-capturing group)
            \[ (?P<extras>[a-zA-Z0-9,._-]+) \]  # Extras (optional)
        )?
        (?:  # Version comparison operator and version number
            (?P<operator>==|!=|<=|>=|<|>|~=)
            (?P<version>[a-zA-Z0-9.*+!<>-]+)
        )?
        (?:  # Environment markers
            ;\s*(?P<marker>.+)
        )?
    |
        # Comments
        \#.*$
    |
        # URL or editable installations
        (?P<url>https?://[^\s]+ | git\+[^\s]+)
        (?:\#egg=(?P<egg>[a-zA-Z0-9._-]+))?
    |
        # Editable install flag
        -e\s+(?P<editable>git\+[^\s]+(?:\#egg=[a-zA-Z0-9._-]+)?)
    )
    \s*$  # Allow trailing whitespace
    """
    
    # Compile the regex pattern with VERBOSE flag for better readability
    regex = re.compile(pattern, re.VERBOSE)

    # Match the input string against the regex pattern
    return bool(regex.match(string))

if __name__ == "__main__":
    # Examples of usage
    print(is_requirements_format("package-name==1.0.0"))  # True
    print(is_requirements_format("package-name[extra1, extra2]>=2.0.0"))  # True
    print(is_requirements_format("git+https://github.com/user/repo.git"))  # True
    print(is_requirements_format("-e git+https://github.com/user/repo.git#egg=package"))  # True
    print(is_requirements_format("invalid-package-name==="))  # False
