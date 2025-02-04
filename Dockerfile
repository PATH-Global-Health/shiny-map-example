# Start with the official R base image
FROM rocker/shiny:latest

# Install system dependencies required for R packages
RUN apt-get update && apt-get install -y \
    libcurl4-gnutls-dev \
    libssl-dev \
    libxml2-dev \
    libgdal-dev \
    libudunits2-dev \
    libgeos-dev \
    libproj-dev \
    && rm -rf /var/lib/apt/lists/*

# Install required R packages
RUN R -e "install.packages(c(\
    'shiny', \
    'shinyauthr', \
    'bslib', \
    'tidyverse', \
    'tmap', \
    'sf' \
    ), \
    repos='https://cran.rstudio.com/')"

# Create app directory
RUN mkdir /app

# Copy app files into container
COPY app.R /app/
COPY data/ng_data.rds /app/data/

# Set working directory
WORKDIR /app

# Expose port 3838 (default Shiny port)
EXPOSE 3838

# Run the Shiny app
CMD ["R", "-e", "shiny::runApp('/app', host = '0.0.0.0', port = 3838)"]