package com.breakersoft.plow.scheduler.dao;

import com.breakersoft.plow.rnd.thrift.RunningTask;

public interface StatsDao {

    boolean updateRuntimeStats(RunningTask task);

}
