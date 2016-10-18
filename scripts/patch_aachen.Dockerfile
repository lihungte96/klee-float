FROM comsys/klee-dev-fpbench-prebuilt:latest
MAINTAINER Dan Liew <daniel.liew@imperial.ac.uk>

ARG host_user_id=1000
# This isn't really a build arg. It's just a convenient way of declaring a variable
# that we can use in the Dockerfile.
ARG container_username=user

# Remove old KLEE code
RUN rm -rf /home/${container_username}/klee && mkdir /home/${container_username}/klee

# Need to be root to make these changes
USER root

# Install python dependencies for fp-bench
RUN pip install PyYAML==3.12 jsonschema==2.5.1

# Change the UID of the user "user" to have the specified UID.
# The usermod  manual claims that it will fix permissions of
# the user's home directory and its contents automatically
RUN usermod --uid ${host_user_id} ${container_username}

# Make sure the home directory can be read by everyone.
# This should fix permission problems where klee-runner uses
# a different user id to the user id for "user" in the container.
RUN chmod 0755 /home/${container_username}/

# Switch back to "user"
USER ${container_username}

# Copy the modified makefile into the correct location.
# It is patched to have slightly different behaviour to Aachen's
# default.
ADD scripts/container.Makefile /home/${container_username}/makefile

# Grab whole-program-llvm
RUN git clone --depth 1 https://github.com/travitch/whole-program-llvm.git /home/${container_username}/whole-program-llvm && echo "PATH=\$PATH:/home/${container_username}/whole-program-llvm" >> /home/${container_username}/.bashrc

# Copy in KLEE sources to where the should be
ADD / /home/${container_username}/klee/
# Fix permissions
USER root
RUN chown -R ${container_username}: /home/${container_username}/klee/ && \
    chown ${container_username}: /home/${container_username}/makefile
USER ${container_username}

# Build KLEE
WORKDIR /home/${container_username}/
RUN make klee
# Install
RUN cd /home/${container_username}/klee/build && sudo make install && sudo ldconfig -n /usr/local/lib

# Setup environment for shell so fp-bench is easy to build
RUN echo "export KLEE_NATIVE_RUNTIME_INCLUDE_DIR=/home/user/klee/include/" >> /home/user/.bashrc && \
    echo "export KLEE_NATIVE_RUNTIME_LIB_DIR=/home/user/klee/build/Release+Asserts/lib/" >> /home/user/.bashrc

