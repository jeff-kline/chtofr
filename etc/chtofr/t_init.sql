/*
table t_channel
  channel_pk, channel(u)

table t_ch_prefix
  ch_prefix_pk, ch_prefix(u)

table t_frame_type
  frame_type_pk, frame_type(u)

table t_frame_info
  frame_info_pk, (frame_type_pk, gps)(u), nchannels, fpath, ...

table t_map
  ch_prefix_pk, channel_pk, frame_type_pk, gps
*/

CREATE TABLE IF NOT EXISTS t_channel (
    `channel_pk` INTEGER(11) UNSIGNED NOT NULL  AUTO_INCREMENT,
    `channel` VARCHAR(255)  NOT NULL,

    /* meta */
    PRIMARY KEY (`channel_pk`),
    UNIQUE INDEX (`channel`)
) ENGINE=InnoDB CHARACTER SET latin1 COLLATE latin1_bin;

CREATE TABLE IF NOT EXISTS t_ch_subsystem (
    `ch_subsystem_pk` INTEGER(11) UNSIGNED NOT NULL  AUTO_INCREMENT,
    `ch_subsystem` VARCHAR(16)  NOT NULL,

    /* meta */
    PRIMARY KEY (`ch_subsystem_pk`),
    UNIQUE INDEX (`ch_subsystem`)
) ENGINE=InnoDB CHARACTER SET latin1 COLLATE latin1_bin;

CREATE TABLE IF NOT EXISTS t_ch_prefix (
    `ch_prefix_pk` INTEGER(11) UNSIGNED NOT NULL  AUTO_INCREMENT,
    `ch_prefix` VARCHAR(16)  NOT NULL,

    /* meta */
    PRIMARY KEY (`ch_prefix_pk`),
    UNIQUE INDEX (`ch_prefix`)
) ENGINE=InnoDB CHARACTER SET latin1 COLLATE latin1_bin;

CREATE TABLE IF NOT EXISTS t_ch_attr (
    `ch_attr_pk` INTEGER(11) UNSIGNED NOT NULL  AUTO_INCREMENT,
    `ch_attr` VARCHAR(16)  NOT NULL,

    /* meta */
    PRIMARY KEY (`ch_attr_pk`),
    UNIQUE INDEX (`ch_attr`)
) ENGINE=InnoDB CHARACTER SET latin1 COLLATE latin1_bin;

CREATE TABLE IF NOT EXISTS t_frame_type (
    `frame_type_pk` INTEGER(11) UNSIGNED NOT NULL  AUTO_INCREMENT,
    `frame_type` VARCHAR(255)  NOT NULL,

    /* meta */
    PRIMARY KEY (`frame_type_pk`),
    UNIQUE INDEX (`frame_type`)
) ENGINE=InnoDB CHARACTER SET latin1 COLLATE latin1_bin;

CREATE TABLE IF NOT EXISTS t_frame_info (
    `frame_info_pk` INTEGER UNSIGNED NOT NULL  AUTO_INCREMENT,
    `frame_type_pk` INTEGER UNSIGNED NOT NULL,
    `gps` INTEGER UNSIGNED NOT NULL,
    `nchannels` INTEGER UNSIGNED NOT NULL,
    `fpath` VARCHAR(1024) NOT NULL,

    /* meta */
    PRIMARY KEY (`frame_info_pk`),
    UNIQUE INDEX (`frame_type_pk`, `gps`),
    FOREIGN KEY (`frame_type_pk`) REFERENCES t_frame_type(`frame_type_pk`)
) ENGINE=InnoDB CHARACTER SET latin1 COLLATE latin1_bin;

/* ch_prefix_pk, channel_pk, frame_info_pk */
CREATE TABLE IF NOT EXISTS t_map (
    `map_pk` BIGINT UNSIGNED NOT NULL  AUTO_INCREMENT,
    `ch_prefix_pk` INTEGER UNSIGNED NOT NULL,
    `ch_subsystem_pk` INTEGER UNSIGNED NOT NULL,
    `ch_attr_pk` INTEGER UNSIGNED NOT NULL,
    `channel_pk` INTEGER UNSIGNED NOT NULL,
    `frame_info_pk` INTEGER UNSIGNED NOT NULL,

    /* meta */
    PRIMARY KEY (`map_pk`),
    UNIQUE INDEX (`ch_prefix_pk`, `ch_subsystem_pk`, `channel_pk`, `ch_attr_pk`, `frame_info_pk`),
    FOREIGN KEY (`ch_prefix_pk`) REFERENCES t_ch_prefix(`ch_prefix_pk`),
    FOREIGN KEY (`ch_subsystem_pk`) REFERENCES t_ch_subsystem(`ch_subsystem_pk`),
    FOREIGN KEY (`ch_attr_pk`) REFERENCES t_ch_attr(`ch_attr_pk`),
    FOREIGN KEY (`channel_pk`) REFERENCES t_channel(`channel_pk`),
    FOREIGN KEY (`frame_info_pk`) REFERENCES t_frame_info(`frame_info_pk`)
) ENGINE=InnoDB CHARACTER SET latin1 COLLATE latin1_bin;
