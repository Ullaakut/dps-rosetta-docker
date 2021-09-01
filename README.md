## Docker packaging of Flow Rosetta API implementation

This is a work in progress and subject to change.

## Supported sporks

 Name     | Lowest block | Highest block 
----------|--------------|--------------
Mainnet-5 | 12020337     | 12609236

## Building and running

Dockerfile is self-contained - it downloads all code and configuration it needs from a git repository, as 
designated by Rosetta requirements.

It can be build without any extra arguments: 
`docker build .`

On first run the DPS index snapshot will be downloaded and unpacked. Since those files are large 
it's advisable to provide a fixed mountpoint for running container with `/data/` path.

