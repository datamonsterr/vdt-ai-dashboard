from setuptools import find_packages, setup

setup(
    name="vdt-ai",
    version="1.0.0",
    description="VDT AI Python Library for data processing and ML operations",
    author="datamosnterr",
    author_email="phamdat17092004@gmai.com",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    python_requires=">=3.8",
    install_requires=[
        "grpcio>=1.50.0",
        "grpcio-tools>=1.50.0",
        "protobuf>=4.0.0",
        "kafka-python>=2.0.0",
        "pydantic>=1.10.0",
        "click>=8.0.0",
        "loguru>=0.6.0",
        "requests>=2.28.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.0.0",
            "pytest-cov>=4.0.0",
            "black>=22.0.0",
            "isort>=5.10.0",
            "flake8>=5.0.0",
            "mypy>=0.991",
            "types-requests",
        ],
    },
    entry_points={
        "console_scripts": [
            "vdt-ai=vdt_ai.cli:main",
        ],
    },
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
)
