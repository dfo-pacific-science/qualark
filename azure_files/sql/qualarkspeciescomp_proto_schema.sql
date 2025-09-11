IF NOT EXISTS (
  SELECT 1
    FROM sys.databases
   WHERE name = N'sqldb-qualarkspeciescomp-proto'
)
  CREATE DATABASE [sqldb-qualarkspeciescomp-proto];
GO

USE [sqldb-qualarkspeciescomp-proto];
GO

-- Create 'locations' table
CREATE TABLE [dbo].[locations] (
    location_id      CHAR(1) PRIMARY KEY,          -- e.g., 'n', 'f'
    location_name    VARCHAR(50) NOT NULL          -- e.g., 'near', 'far'
);
GO

-- Create 'mesh_sizes' table
CREATE TABLE [dbo].[mesh_sizes] (
    mesh_id     INT PRIMARY KEY IDENTITY(1,1),
    mesh_size   DECIMAL(5,2) NOT NULL           -- e.g., 4.00, 4.25
);
GO

-- Create 'species' table
CREATE TABLE [dbo].[species] (
    species_id       INT PRIMARY KEY IDENTITY(1,1),
    species_code     VARCHAR(5) UNIQUE NOT NULL,   -- e.g., 'S', 'P', 'U'
    species_name     VARCHAR(50) NOT NULL          -- Common Name, e.g., 'Sockeye'
);
GO

-- Create 'life_history_types' table
CREATE TABLE [dbo].[life_history_types] (
    life_history_type_id INT PRIMARY KEY IDENTITY(1,1),
    lh_type             VARCHAR(50) NOT NULL,      -- e.g., 'Adult', 'Jack'
    lh_code             VARCHAR(10) NOT NULL       -- e.g., 'A', 'J'
);
GO

-- Create 'marked_fish_types' table
CREATE TABLE [dbo].[marked_fish_types] (
    marked_fish_type_id INT PRIMARY KEY IDENTITY(1,1),
    marked_fish_type_code VARCHAR(10) UNIQUE NOT NULL, -- e.g., 'ADC', 'Unm', 'UNK'
    marked_fish_type     VARCHAR(50) NOT NULL          -- e.g., 'Adipose Clipped', 'Unmarked', 'Unknown'
);
GO


-- Create 'sonar_configurations' table
CREATE TABLE [dbo].[sonar_configurations] (
    sonar_config_id    INT PRIMARY KEY IDENTITY(1,1),
    system             VARCHAR(50) NOT NULL,        -- e.g., 'Qualark Ck. DIDSON'
    bank               VARCHAR(20) NOT NULL,        -- e.g., 'RB HF', 'LB LF LR'
    frequency_setting  VARCHAR(28) NOT NULL,        -- e.g., 'High', 'Low', 'Low-Resolution'
    comments           NVARCHAR(MAX)                -- Additional comments or notes about the configuration
);
GO

-- Create 'sonar_counts' table
CREATE TABLE [dbo].[sonar_counts] (
    sonar_count_id     INT PRIMARY KEY IDENTITY(1,1),
    sonar_config_id    INT NOT NULL,                 -- Foreign Key to sonar_configurations
    date               DATE NOT NULL,
    count_hour         INT NOT NULL CHECK (count_hour BETWEEN 0 AND 23), -- Hour identifier
    duration_minutes   INT,                          -- Duration of the count period in minutes
    up                 INT,                          -- Number of fish moving Upstream
    down               INT,                          -- Number of fish moving Downstream
    net_up             INT,                          -- Net Upstream movement
    salmon_per_hour    DECIMAL(6,2),                 -- Number of salmon per hour
    comments           NVARCHAR(MAX),                -- Any additional comments related to the count
    FOREIGN KEY (sonar_config_id) REFERENCES [dbo].[sonar_configurations](sonar_config_id)
);
GO

-- Create 'drifts' table with foreign keys including ON DELETE CASCADE
CREATE TABLE [dbo].[drifts] (
    drift_id         INT PRIMARY KEY IDENTITY(1,1),
    drift_date       DATE NOT NULL,
    drift_number     INT NOT NULL,
    location_id      CHAR(1) NOT NULL,              -- Foreign Key to locations
    start_time       TIME,
    end_time         TIME,
	duration_minutes TIME,
    mesh_id          INT,                           -- Foreign Key to mesh_sizes
    comments         NVARCHAR(MAX),
    FOREIGN KEY (location_id) REFERENCES [dbo].[locations](location_id) ON DELETE CASCADE,
    FOREIGN KEY (mesh_id) REFERENCES [dbo].[mesh_sizes](mesh_id) ON DELETE CASCADE
);
GO

-- Create 'fish_samples' table with foreign keys including ON DELETE CASCADE
CREATE TABLE [dbo].[fish_samples] (
    fish_sample_id       INT PRIMARY KEY IDENTITY(1,1),
    drift_id            INT NOT NULL,                  -- Foreign Key to drifts
    species_id          INT NOT NULL,                  -- Foreign Key to species
    retention_type      VARCHAR(10) NOT NULL,          -- "Retained" or "Released"
    life_history_type_id INT,                           -- Foreign Key to life_history_types (optional)
    catch_count         INT,                           -- Number of fish
    adipose_status      INT,                           -- Foreign Key to marked_fish_types (optional)
    additional_info     VARCHAR(255),                  -- e.g., "Ad P", "Ad A", "Ad Unk"
    FOREIGN KEY (drift_id) REFERENCES [dbo].[drifts](drift_id) ON DELETE CASCADE,
    FOREIGN KEY (species_id) REFERENCES [dbo].[species](species_id) ON DELETE CASCADE,
    FOREIGN KEY (life_history_type_id) REFERENCES [dbo].[life_history_types](life_history_type_id) ON DELETE CASCADE,
    FOREIGN KEY (adipose_status) REFERENCES [dbo].[marked_fish_types](marked_fish_type_id) ON DELETE CASCADE
);
GO




ALTER TABLE [dbo].[fish_samples]
ADD CONSTRAINT FK_fish_samples_drifts
FOREIGN KEY (drift_id)
REFERENCES [dbo].[drifts](drift_id);


CREATE UNIQUE INDEX UIX_sonarcounts_config_date_hour
ON dbo.sonar_counts (sonar_config_id, date, count_hour);
GO


ALTER TABLE [dbo].[drifts]
ADD CONSTRAINT UQ_drifts_unique
UNIQUE (drift_date, drift_number);

ALTER TABLE [dbo].[fish_samples]
ADD CONSTRAINT UQ_fish_samples_unique
UNIQUE (drift_id, species_id, life_history_type_id, adipose_status, retention_type);


ALTER TABLE [dbo].[sonar_counts]
ADD created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE(),
    updated_by VARCHAR(50) DEFAULT 'Initial_Load';

ALTER TABLE [dbo].[drifts]
ADD created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE(),
    updated_by VARCHAR(50) DEFAULT 'Initial_Load';

ALTER TABLE [dbo].[fish_samples]
ADD created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE(),
    updated_by VARCHAR(50) DEFAULT 'Initial_Load'; 
