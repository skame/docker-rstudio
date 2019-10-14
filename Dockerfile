FROM rocker/tidyverse:latest

LABEL maintainer "KAMEI Satoshi <skame@nttv6.jp>"

RUN rm -rf /var/lib/apt/lists/* && apt-get update && \
	DEBIAN_FRONTEND=noninteractive && export DEBIAN_FRONTEND && \
        apt-get install -y --no-install-recommends software-properties-common supervisor wget openssh-server sudo \
        git-core fonts-vlgothic nkf jq \
	rsync gawk netcat curl libglu1-mesa-dev libx11-dev libv8-dev xorg \
# for ldap
	libpam-ldapd tcsh libnss-ldapd && \
        apt-get clean && rm -rf /var/lib/apt/lists/* && \
        echo session required                        pam_mkhomedir.so umask=0022 skel=/etc/skel >> /etc/pam.d/common-session && \
        echo session required                        pam_mkhomedir.so umask=0022 skel=/etc/skel >> /etc/pam.d/common-session-noninteractive && \
# locale
	sed -ir 's/# ja_JP.UTF-8 UTF-8/ja_JP.UTF-8 UTF-8/' /etc/locale.gen && locale-gen && update-locale LANG=ja_JP.UTF-8
# for build
RUN apt-get update && apt-get install -y --no-install-recommends \
	libudunits2-dev libgdal-dev && \
        apt-get clean && rm -rf /var/lib/apt/lists/*
# rJava
RUN apt-get update && apt-get install -y --no-install-recommends libbz2-dev libpcre3-dev openjdk-8-jdk liblzma-dev && R CMD javareconf && \
        apt-get clean && rm -rf /var/lib/apt/lists/*
# R packages
RUN installGithub.r tidyverse/tidyverse
RUN install2.r --error ggvis googleVis htmlwidgets lubridate mailR pipeR readxl rlist tidyr RCurl gridExtra DT xts forecast \
    caret base64enc dlm KFAS lda Matrix ca cluster fpc elastic readr foreach bit64 Rcpp doParallel rio e1071 jsonlite \
    pbapply ROCR randomForest nloptr digest xtable reshape2 knitrBootstrap magrittr knitr plyr \
    d3heatmap networkD3 ggmap sitools visNetwork rkafka gsheet RJSONIO GGally outliers leaflet formattable fasttime TSclust listless \
    rgeolocate ggfortify
RUN installGithub.r Rdatatable/data.table jimhester/knitrBootstrap
RUN installGithub.r rstudio/rmarkdown yihui/formatR ramnathv/rCharts ramnathv/htmlwidgets bokeh/rbokeh yihui/knitr smartinsightsfromdata/rpivotTable
# plotly
RUN installGithub.r ropensci/plotly
# ggnet
RUN installGithub.r briatte/ggnet && \
    install2.r --error network sna
# Dashboard flexdashboard treeMap radermap
RUN installGithub.r rstudio/flexdashboard timelyportfolio/d3treeR ricardo-bion/ggradar && \
    install2.r --error fmsb treemap

# DB management libraries / MySQL, PostgreSQL, Presto
RUN apt-get update && apt-get install -y --no-install-recommends libpq-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    install2.r --error RPostgreSQL RMySQL RMariaDB dbplyr && \
    installGithub.r rstats-db/DBI hadley/dtplyr prestodb/RPresto@7515927f989ecea

# cymru whois, iptools
RUN install2.r pingr triebeard AsioHeaders && \
	installGithub.r hrbrmstr/cymruservices hrbrmstr/iptools
# jqr
RUN apt-get update && apt-get install -y --no-install-recommends libjq-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    install2.r jqr

# rrdtool
RUN apt-get update && apt-get install -y --no-install-recommends rrdtool librrd-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    installGithub.r pldimitrov/Rrd
# nodbi
RUN installGithub.r ropensci/nodbi
# ODBC
RUN installGithub.r r-dbi/odbc

# RMeCab packages
# for MeCab (DO NOT use ubuntu repos version for rmecab)
RUN curl 'https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7cENtOXlicTFaRUE' -Lo mecab-0.996.tar.gz && \
    curl 'https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7MWVlSDBCSXZMTXM' -Lo mecab-ipadic-2.7.0-20070801.tar.gz && \
    tar -xzf mecab-0.996.tar.gz && tar -xzf mecab-ipadic-2.7.0-20070801.tar.gz && \
    (cd mecab-0.996 || exit; ./configure --with-charset="utf8"; make all; make install); ldconfig; (cd mecab-ipadic-2.7.0-20070801; ./configure --with-charset="utf-8"; make; make install) && \
    rm -rf mecab-0.996.tar.gz* && rm -rf mecab-ipadic-2.7.0-20070801*
RUN install2.r --repos http://rmecab.jp/R --error RMeCab
RUN curl -O http://rmecab.jp/R/src/contrib/RMeCab_1.00.tar.gz
RUN R CMD INSTALL RMeCab_1.00.tar.gz
# wordcloud
RUN install2.r wordcloud

# install preview rstudio
#RUN wget --no-check-certificate \
#	https://raw.githubusercontent.com/rocker-org/rstudio-daily/master/latest.R \
#        && sed -i 's/row0/row1/' latest.R \
#	&& Rscript latest.R && rm latest.R \
#	&& dpkg -i rstudio-server-daily-amd64.deb && rm rstudio-server-daily-amd64.deb

# Selenium
RUN install2.r RSelenium
# irtoys 項目応答理論を算出 for IKSU
RUN apt-get update && apt-get install -y --no-install-recommends tk && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
RUN install2.r --error irtoys

# nslcd config & nsswtich config
RUN rm /etc/nslcd.conf
COPY nslcd.conf-template /etc/nslcd.conf-template
COPY nslcd-run.sh /etc/rc.nslcd-run.sh

# R Studio config
COPY rserver.conf /etc/rstudio/
COPY Rprofile.site /etc/R/
# for supervisord
COPY docker.conf /etc/supervisor/conf.d/supervisord.conf

# sigli (for template)
RUN curl -Ls https://github.com/gliderlabs/sigil/releases | \
  grep -E -o '/gliderlabs/sigil/.*sigil_[0-9\.]+_Linux_x86_64.tgz' | head -1 | \
  (curl -Lo sigil.tgz http://github.com/"$(cat)") \
  && tar xzf sigil.tgz -C /bin \
  && rm sigil.tgz && sigil -v

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

