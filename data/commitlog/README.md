# Git Commit Log

A data set to work on timestamps, provided by pgloader's git:

    git log --format='pgloader;%H;%an;%aI;%cn;%cI;%f' > pgloader.log
    git log --format='postgresql;%H;%an;%aI;%cn;%cI;%f' > postgresql.log
