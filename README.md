# SQLlite Clone in Ruby

It's simplified implementation of an SQLite-like database engine written in Ruby. This project serves as a learning tool to understand the underlying data structures and operations that drive a relational database.

## Table of Contents

- [About the Project](#about-the-project)
- [Features](#features)
- [Getting Started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Installation](#installation)
- [Usage](#usage)
- [Components](#components)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgments](#acknowledgments)

## About the Project

SQLlite Clone aims to replicate some of the core functionalities of SQLite to provide a practical understanding of how databases work behind the scenes. The clone uses **B-trees** to store data, similar to how actual database systems store and retrieve information efficiently. This project is for educational purposes, designed to explore concepts such as data storage, indexing, parsing, and executing SQL commands.

## Features

- Create simple databases and tables.
- Insert, select, update, and delete operations.
- Data storage using B-trees.
- Command-line interface for executing basic SQL queries.

## Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

- Ruby (>= 2.7)

Ensure you have Ruby installed on your machine. You can check the installed version using:

```sh
ruby -v
```

### Installation

1. Clone the repository:

   ```sh
   git clone https://github.com/atish23/sqllite_clone_ruby.git
   ```

2. Navigate to the project directory:

   ```sh
   cd sqllite_clone_ruby
   ```

3. Install dependencies:

   ```sh
   bundle install
   ```

## Usage

Once you have installed the prerequisites and cloned the project, you can start using SQLlite Clone by running:

```sh
ruby btree_sqllite.rb
```

This will open an interactive shell where you can input basic SQL commands, such as:

- **Create Table**:
  ```sql
  CREATE TABLE users (id INTEGER, name TEXT);
  ```
- **Insert Data**:
  ```sql
  INSERT INTO users (id, name) VALUES (1, 'John Doe');
  ```
- **Select Data**:
  ```sql
  SELECT * FROM users;
  ```

## Components

The project is structured into several core components:

- **Backend Folder**: Contains the logic for handling data storage and retrieval. This includes the implementation of B-trees and other data structures used to store the database tables.
- **Core**: Manages the core functionalities of the database, such as parsing SQL commands, managing schema, and coordinating data operations.
- **Compiler**: Responsible for compiling and interpreting SQL queries into operations that can be executed by the backend.

## Acknowledgments

- [SQLite Documentation](https://www.sqlite.org/docs.html) for inspiration and a better understanding of database internals.
