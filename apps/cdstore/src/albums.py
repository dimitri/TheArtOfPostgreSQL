#! /usr/bin/env python3
# -*- coding: utf-8 -*-

import psycopg2
import psycopg2.extras
import sys
from datetime import timedelta

DEBUGSQL = False
PGCONNSTRING = "user=cdstore dbname=appdev application_name=cdstore"


class Model(object):
    tablename = None
    columns = None

    @classmethod
    def buildsql(cls, pgconn, **kwargs):
        if cls.tablename and kwargs:
            cols = ", ".join(['"%s"' % c for c in cls.columns])
            qtab = '"%s"' % cls.tablename
            sql = "select %s from %s where " % (cols, qtab)
            for key in kwargs.keys():
                sql += "\"%s\" = '%s'" % (key, kwargs[key])
            if DEBUGSQL:
                print(sql)
            return sql


    @classmethod
    def fetchone(cls, pgconn, **kwargs):
        if cls.tablename and kwargs:
            sql = cls.buildsql(pgconn, **kwargs)
            curs = pgconn.cursor(cursor_factory=psycopg2.extras.DictCursor)
            curs.execute(sql)
            result = curs.fetchone()
            if result is not None:
                return cls(*result)

    @classmethod
    def fetchall(cls, pgconn, **kwargs):
        if cls.tablename and kwargs:
            sql = cls.buildsql(pgconn, **kwargs)
            curs = pgconn.cursor(cursor_factory=psycopg2.extras.DictCursor)
            curs.execute(sql)
            resultset = curs.fetchall()
            if resultset:
                return [cls(*result) for result in resultset]


class Artist(Model):
    tablename = "artist"
    columns = ["artistid", "name"]

    def __init__(self, id, name):
        self.id = id
        self.name = name


class Album(Model):
    tablename = "album"
    columns = ["albumid", "title"]

    def __init__(self, id, title):
        self.id = id
        self.title = title
        self.duration = None


class Track(Model):
    tablename = "track"
    columns = ["trackid", "name", "milliseconds", "bytes", "unitprice"]

    def __init__(self, id, name, milliseconds, bytes, unitprice):
        self.id = id
        self.name = name
        self.duration = milliseconds
        self.bytes = bytes
        self.unitprice = unitprice


if __name__ == '__main__':
    if len(sys.argv) > 1:
        pgconn = psycopg2.connect(PGCONNSTRING)
        artist = Artist.fetchone(pgconn, name=sys.argv[1])

        for album in Album.fetchall(pgconn, artistid=artist.id):
            ms = 0
            for track in Track.fetchall(pgconn, albumid=album.id):
                ms += track.duration

            duration = timedelta(milliseconds=ms)
            print("%25s: %s" % (album.title, duration))
    else:
        print('albums.py <artist name>')
