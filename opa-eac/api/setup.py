""" 
opa.api
"""

from setuptools import setup, find_namespace_packages

setup(
    name="opa.api",
    version="1.0.0",
    description="OPA API Library",
    url="https://github.optum.com/opa/opa.api",
    author="Momchil Georgiev",
    author_email="momchil.georgiev@optum.com",
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "Topic :: Software Development :: Build Tools",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3.6",
        "Programming Language :: Python :: 3.7",
    ],
    packages=find_namespace_packages(exclude=["tests", "tests_workflows"]),
    include_package_data=True,
    python_requires=">=3.6",
    install_requires=["boto3==1.9.121", "botocore==1.12.207"],
    project_urls={
        "Source": "https://github.optum.com/opa/opa.api",
        "Bug Reports": "https://github.optum.com/opa/opa.api/issues",
    },
)
