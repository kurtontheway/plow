package com.breakersoft.plow.test.dao;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;

import javax.annotation.Resource;

import org.junit.Test;

import com.breakersoft.plow.Cluster;
import com.breakersoft.plow.Defaults;
import com.breakersoft.plow.Node;
import com.breakersoft.plow.dao.ClusterDao;
import com.breakersoft.plow.dao.NodeDao;
import com.breakersoft.plow.rnd.thrift.Ping;
import com.breakersoft.plow.test.AbstractTest;

public class NodeDaoTests extends AbstractTest {

    @Resource
    NodeDao nodeDao;;

    @Resource
    ClusterDao clusterDao;

    private static final String[] TAGS = new String[] { "test" } ;

    @Test
    public void create() {
        Ping ping = getTestNodePing();
        Cluster cluster = clusterDao.create("test", TAGS);
        Node node = nodeDao.create(cluster, ping);
        assertEquals(cluster.getClusterId(), node.getClusterId());
        assertEquals(ping.getHostname(), node.getName());
    }

    @Test
    public void update() {
        Ping ping = getTestNodePing();
        Cluster cluster = clusterDao.create("test", TAGS);
        Node node = nodeDao.create(cluster, ping);
        nodeDao.update(node, ping);
        ping.isReboot = true;
        nodeDao.update(node, ping);
    }

    @Test
    public void allocateResources() {
        Ping ping = getTestNodePing();
        Cluster cluster = clusterDao.create("test", TAGS);
        Node node = nodeDao.create(cluster, ping);
        nodeDao.allocateResources(node, 1, 1024);

        // Check to ensure the procs/memory were subtracted from the host.
        assertEquals(ping.hw.physicalCpus - 1,
                simpleJdbcTemplate.queryForInt("SELECT int_idle_cores FROM node_dsp WHERE pk_node=?",
                        node.getNodeId()));

        assertEquals(ping.hw.totalRamMb - 1024 - Defaults.MEMORY_RESERVE_MB,
                simpleJdbcTemplate.queryForInt("SELECT int_free_ram FROM node_dsp WHERE pk_node=?",
                        node.getNodeId()));

    }

    public void allocateResourcesFailed() {
        Cluster cluster = clusterDao.create("test", TAGS);
        Node node = nodeDao.create(cluster, getTestNodePing());
        assertFalse(nodeDao.allocateResources(node, 100, 1000000));
    }

    @Test
    public void freeResources() {

        Ping ping = getTestNodePing();
        Cluster cluster = clusterDao.create("test", TAGS);
        Node node = nodeDao.create(cluster, ping);
        nodeDao.allocateResources(node, 1, 1024);
        nodeDao.freeResources(node, 1, 1024);

        assertEquals(ping.hw.physicalCpus,
                simpleJdbcTemplate.queryForInt("SELECT int_idle_cores FROM node_dsp WHERE pk_node=?",
                        node.getNodeId()));

        assertEquals(ping.hw.totalRamMb - Defaults.MEMORY_RESERVE_MB,
                simpleJdbcTemplate.queryForInt("SELECT int_free_ram FROM node_dsp WHERE pk_node=?",
                        node.getNodeId()));
    }
}
