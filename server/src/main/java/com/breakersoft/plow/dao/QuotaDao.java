package com.breakersoft.plow.dao;

import java.util.UUID;

import com.breakersoft.plow.Cluster;
import com.breakersoft.plow.Node;
import com.breakersoft.plow.Proc;
import com.breakersoft.plow.Project;
import com.breakersoft.plow.Quota;
import com.breakersoft.plow.Task;

public interface QuotaDao {

    Quota create(Project project, Cluster cluster, int size, int burst);

    Quota get(UUID id);

    Quota getQuota(Node node, Task task);

    void free(Quota quota, int cores);

    Quota getQuota(Proc proc);

    void setSize(Quota quota, int size);

    void setBurst(Quota quota, int burst);

    void setLocked(Quota quota, boolean locked);

    void allocate(Cluster cluster, Project project, int cores);

    boolean check(Cluster cluster, Project project);

}
