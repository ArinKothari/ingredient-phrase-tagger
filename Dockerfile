FROM ubuntu:16.04

RUN apt-get update -y && apt-get upgrade -y
RUN apt-get install -y build-essential git python2.7 python-pip ruby
RUN pip install pip==20.3.4
RUN pip install numpy
RUN pip install --index-url=https://pypi.org/simple/ pandas==0.17.1
RUN pip install Unidecode==0.04.14
RUN apt-get install ruby -y

# Install CRF++.
RUN git clone https://github.com/mtlynch/crfpp.git && \
    cd crfpp && \
    ./configure && \
    make && \
    make install && \
    ldconfig && \
    cd ..

# Install ingredient-phrase-tagger.
RUN git clone https://github.com/ArinKothari/ingredient-phrase-tagger.git && \
    cd ingredient-phrase-tagger && \
    python setup.py install


WORKDIR /ingredient-phrase-tagger