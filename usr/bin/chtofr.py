#!/usr/bin/env python
import cPickle as pickle
import numbers


DEFAULT_STEP=10800 # 8 hours
DEFAULT_DATABASE_FILE = "/etc/chtofr/db.json"

# store known pk's to avoid multiple lookups this can also be
# populated from a file, but still want it as a global variable.
CACHED_PK={}

def _pk(conn, tname, arg, col=None, ):
    """
    conn: open connection to database
    tname: type name for database tables/column names
    arg: the value to set or get
    col: optional column list. If None, then it will be set to tname.

    SELECT "${tname}_pk" FROM t_${tname} WHERE  ${tname} = ${arg}

    each column in col_l
    equals corresponding value in arg_l"""

    # make two attempts to get the pk value: cached version and then
    # sql version. Assuming both fail, then insert to db and then do a
    # final select to return it
    try: 
        return CACHED_PK[(tname, arg)]
    except KeyError: 
        pass

    # a pair of sql string formatting functions
    def sqlvstr(v):
        # this is fine since we only use strings and integer-like types
        return "'%s'" % str(v)
    def sqlcstr(v):
        return "`%s`" % str(v)

    # build the sql
    select_str = "SELECT `${tname}_pk` FROM `t_${tname}` WHERE "
    if col is None:
        sel_suffix="`${tname}` = '${arg}'"
        ins_suffix=sel_suffix
    else:
        _suffix=[ sqlcstr(c) + " = " + sqlvstr(v) for c,v in zip(col,arg)]
        sel_suffix=' AND '.join(_suffix)
        ins_suffix=', '.join(_suffix) 

    # try to get from database, insert in db if not available
    sql_dict={"tname": tname, "arg": arg}
    select_tmpl=Template(select_str + sel_suffix)
    select_sql=select_tmpl.substitute(sql_dict)
    pk_rp = conn.execute(select_sql).fetchone()
    if pk_rp is None:
        insert_str="INSERT INTO `t_${tname}` SET " + ins_suffix
        insert_tmpl=Template(insert_str)
        insert_sql=insert_tmpl.substitute(sql_dict)
        rp=conn.execute(insert_sql)
        pk_rp = conn.execute(select_sql).fetchone()
    CACHED_PK[(tname,arg)]=pk_rp[0]
    return CACHED_PK[(tname, arg)]

def _input_many(conn, fh, **kwargs):
    """
    conn: open connection to db
    fh: open filehandle to file with lines like this:
    ch_prefix channel frame_type gps nchannels fpath
    """
    for line in fh:
        _input_one(conn, *line.split(), **kwargs)

def _input_one(conn, ch_prefix, channel, frame_type, gps, nchannels, fpath, step=DEFAULT_STEP):
    """
    insert the args into database pointed to by conn.
    
    conn must be open connection to database

    gps must be factor of DEFAULT_STEP
    """

    if int(gps) / step * step != int(gps):
        raise RuntimeError("gps must be multiple of %d" % step)

    # start a transaction with each insert
    with conn.begin():
        # create or read the primary keys:
        ch_prefix_pk = _pk(conn, "ch_prefix", ch_prefix)
        channel_pk = _pk(conn, "channel", channel)
        frame_type_pk = _pk(conn, "frame_type", frame_type)
        frame_info_pk = _pk(conn, "frame_info", 
                            (frame_type_pk, gps, nchannels, fpath), 
                            col=("frame_type_pk", "gps", "nchannels", "fpath"))
        map_pk = _pk(conn, "map", (ch_prefix_pk, channel_pk, frame_info_pk), 
                     col=("ch_prefix_pk", "channel_pk", "frame_info_pk"))

if __name__ == "__main__":
    from optparse import OptionParser
    from sqlalchemy import create_engine, MetaData
    from string import Template
    import json
    import sys

    usage = "usage: %prog [options]"
    description = """The db witer of frame channel data. Input is plain text with fields
    'ch_prefix channel frame_type gps nchannels fname'. It is an error
    to write rows to db that would cause uniqueness constraints in the
    db to be violated. This is a potential issue for (frametype, gps)
    key that is associated with multiple filepaths or nchannels. """
    version = "%prog 0.1"

    parser = OptionParser(usage, version=version, description=description)
    parser.add_option("-d", "--database",
                      help="[default: %s] Configuration file for database access" %
                      (DEFAULT_DATABASE_FILE), default=DEFAULT_DATABASE_FILE)
    helpstr="""[default: %d] GPS step size.  Every gps time in INPUT must be a
               multiple of STEP. This is for debugging.""" % (DEFAULT_STEP)
    parser.add_option("-s", "--step",
                      help=helpstr, default=DEFAULT_STEP, type="int")
    parser.add_option("-i", "--input",
                      help="[default: -] input file", default=None)
    parser.add_option("-c", "--cache",
                      help="[default: None] cache file", default=None)

    (opts, args) = parser.parse_args()

    # renew CACHED_PK before it contains anything
    if opts.cache:
        try:
            with open(opts.cache, 'r') as fh:
                CACHED_PK=pickle.load(fh)
        except: pass

    with open(opts.database) as fh:
        db = json.load(fh)["db"]
    url_tmpl = Template("${type}://${user}:${passwd}@${host}/${db}")
    url = url_tmpl.substitute(db)
    engine = create_engine(url, pool_recycle=3600, max_overflow=30)
    metadata = MetaData(bind=engine)
    metadata.reflect()

    with engine.connect() as conn:
        if opts.input:
            with open(opts.input, 'r') as fh:
                _input_many(conn, fh, step=opts.step)
        else:
            _input_many(conn, sys.stdin)

    if opts.cache:
        with open(opts.cache, 'w') as fh:
            pickle.dump(CACHED_PK, fh)
