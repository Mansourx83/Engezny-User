# Use the official Dart image
FROM dart:3.4.0 AS build

# Install dependencies and Flutter
RUN apt-get update && \
    apt-get install -y curl unzip git xz-utils zip libglu1-mesa && \
    git clone https://github.com/flutter/flutter.git -b stable /flutter && \
    /flutter/bin/flutter doctor

# Set Flutter environment variables
ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:${PATH}"
ENV FLUTTER_ROOT="/flutter"

# Create a new user 'flutteruser' and set the home directory
RUN useradd -ms /bin/bash flutteruser

# Ensure 'flutteruser' has ownership of the Flutter SDK
RUN chown -R flutteruser:flutteruser /flutter

# Configure git to recognize the Flutter directory as safe
RUN git config --global --add safe.directory /flutter

# Set the working directory
WORKDIR /app

# Copy the pubspec files and set the correct ownership
COPY pubspec.* ./
RUN chown -R flutteruser:flutteruser /app

# Switch to 'flutteruser'
USER flutteruser

# Disable Flutter analytics
RUN flutter config --no-analytics

# Run 'flutter pub get' as 'flutteruser'
RUN flutter pub get

# Switch back to root to copy the rest of the application files
USER root
COPY . .
RUN chown -R flutteruser:flutteruser /app

# Switch to 'flutteruser' again
USER flutteruser

# Ensure Flutter dependencies are up-to-date
RUN flutter pub get

# Build the Flutter web application
RUN flutter build web

# Use a minimal base image to serve the web application
FROM nginx:alpine

# Copy the built web application to the nginx html directory
COPY --from=build /app/build/web /usr/share/nginx/html

# Expose port 80 to serve the application
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
