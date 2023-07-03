FROM main

# Forces rebuild of container when code generator is updated
COPY .code_generator_version /.code_generator_version

# Add test dependencies
COPY codeship-test/chef /.chef/
COPY codeship-test/*.sh /
COPY codeship-test/crypto.py /crypto.py
RUN mkdir -p /root/.aws
COPY codeship-test/aws_config /root/.aws/config
# Optimize so gems/bundler are only rebuilt when they change
RUN mkdir -p /repo/.bundle
COPY .bundle/config /repo/.bundle/config
COPY Gemfile /repo/Gemfile
RUN cd /repo && bundle install
COPY . /repo/

RUN pip install -r /repo/codeship-test/pr/requirements.txt

# Set entrypoint
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
