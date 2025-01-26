FROM postgres:14
ENV POSTGRES_USER=admin
ENV POSTGRES_PASSWORD=admin123
ENV POSTGRES_DB=message_board

COPY init.sql /docker-entrypoint-initdb.d/
