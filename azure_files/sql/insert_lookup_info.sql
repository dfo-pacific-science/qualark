DELETE FROM [dbo].[locations];
GO

SET IDENTITY_INSERT [dbo].[locations] ON;
GO

INSERT INTO [dbo].[locations] (location_id, location_name) VALUES ('n', 'near'),
('f', 'far');
GO

SET IDENTITY_INSERT [dbo].[locations] OFF;
GO


DELETE FROM [dbo].[life_history_types];
GO

SET IDENTITY_INSERT [dbo].[life_history_types] ON;
GO

INSERT INTO [dbo].[life_history_types] (life_history_type_id, lh_type, lh_code) VALUES (1, 'adult', 'A'),
(2, 'baseline', 'B'),
(3, 'fence', 'Fen'),
(4, 'fecundity', 'F'),
(5, 'jacks', 'J'),
(6, 'kokanee', 'K'),
(7, 'residual', 'R'),
(8, 'smolts', 'S'),
(9, 'tagging', 'T'),
(11, 'hatchery', 'H');
GO

SET IDENTITY_INSERT [dbo].[life_history_types] OFF;
GO


DELETE FROM [dbo].[marked_fish_types];
GO

SET IDENTITY_INSERT [dbo].[marked_fish_types] ON;
GO

INSERT INTO [dbo].[marked_fish_types] (marked_fish_type_id, marked_fish_type_code, marked_fish_type) VALUES (1, 'ADC', 'Adipose Clipped'),
(8, 'Unm', 'Unmarked'),
(42, 'UNK', 'Unknown');
GO

SET IDENTITY_INSERT [dbo].[marked_fish_types] OFF;
GO


DELETE FROM [dbo].[mesh_sizes];
GO

SET IDENTITY_INSERT [dbo].[mesh_sizes] ON;
GO

INSERT INTO [dbo].[mesh_sizes] (mesh_id, mesh_size) VALUES (1.0, 4.0),
(4.0, 4.75),
(5.0, 5.25),
(6.0, 6.0),
(7.0, 6.75),
(8.0, 7.75),
(10.0, 5.75),
(17.0, 8.0),
(26.0, 4.625),
(32.0, 8.75);
GO

SET IDENTITY_INSERT [dbo].[mesh_sizes] OFF;
GO


DELETE FROM [dbo].[sonar_configurations];
GO

SET IDENTITY_INSERT [dbo].[sonar_configurations] ON;
GO

INSERT INTO [dbo].[sonar_configurations] (sonar_config_id, system, bank, frequency_setting, comments) VALUES (1, 'DIDSON', 'Right Bank', 'Low Frequency', NULL),
(2, 'DIDSON', 'Left Bank', 'Low Frequency Low Resolution', NULL),
(3, 'DIDSON', 'Right Bank', 'Low Frequency Low Resolution', NULL),
(4, 'DIDSON', 'Right Bank', 'High Frequency', NULL),
(5, 'DIDSON', 'Left Bank', 'High Frequency', NULL),
(6, 'DIDSON', 'Left Bank', 'Low Frequency', NULL);
GO

SET IDENTITY_INSERT [dbo].[sonar_configurations] OFF;
GO


DELETE FROM [dbo].[species];
GO

SET IDENTITY_INSERT [dbo].[species]  ON;
GO

INSERT INTO [dbo].[species] (species_id, species_code, species_name) VALUES (2, 'S', 'sockeye'),
(3, 'P', 'pink'),
(4, 'U', 'unknown'),
(13, 'CM', 'chum'),
(14, 'CO', 'coho'),
(15, 'CK', 'chinook'),
(16, 'CT', 'sutthroat'),
(17, 'ST', 'steelhead');
GO

SET IDENTITY_INSERT [dbo].[species]  OFF;
GO
