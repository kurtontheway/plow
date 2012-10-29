package com.breakersoft.plow.test.dao;

import static org.junit.Assert.*;

import javax.annotation.Resource;

import org.junit.Before;
import org.junit.Test;

import com.breakersoft.plow.Node;
import com.breakersoft.plow.Proc;
import com.breakersoft.plow.Task;
import com.breakersoft.plow.dao.DispatchDao;
import com.breakersoft.plow.dao.ProcDao;
import com.breakersoft.plow.dispatcher.DispatchService;
import com.breakersoft.plow.dispatcher.domain.DispatchJob;
import com.breakersoft.plow.dispatcher.domain.DispatchLayer;
import com.breakersoft.plow.dispatcher.domain.DispatchNode;
import com.breakersoft.plow.dispatcher.domain.DispatchProc;
import com.breakersoft.plow.dispatcher.domain.DispatchTask;
import com.breakersoft.plow.event.JobLaunchEvent;
import com.breakersoft.plow.service.JobService;
import com.breakersoft.plow.service.NodeService;
import com.breakersoft.plow.test.AbstractTest;

public class ProcDaoTests extends AbstractTest {

    @Resource
    NodeService nodeService;

    @Resource
    DispatchDao dispatchDao;

    @Resource
    JobService jobService;

    @Resource
    DispatchService dispatchService;

    @Resource
    ProcDao procDao;;

    private Proc proc;

    private Task task;


    @Before
    public void init() {

        Node node =  nodeService.createNode(getTestNodePing());
        DispatchNode dnode = dispatchDao.getDispatchNode(node.getName());

        JobLaunchEvent event = jobService.launch(getTestBlueprint());
        DispatchJob djob = dispatchDao.getDispatchJob(event.getJob());

        for (DispatchLayer layer: dispatchDao.getDispatchLayers(djob, dnode)) {
            for (DispatchTask dtask: dispatchDao.getDispatchTasks(layer, dnode)) {
                proc = dispatchService.createProc(dnode, dtask);
                task = dtask;
                break;
            }
        }
    }

    @Test
    public void testGetProcById() {
        Proc otherProc = procDao.getProc(proc.getProcId());
        assertEquals(proc.getProcId(), otherProc.getProcId());
        assertEquals(proc.getHostname(), otherProc.getHostname());
        assertEquals(proc.getNodeId(), otherProc.getNodeId());
        assertEquals(proc.getQuotaId(), otherProc.getQuotaId());
        assertEquals(proc.getTaskId(), otherProc.getTaskId());
    }

    @Test
    public void testGetProcByTask() {
        Proc otherProc = procDao.getProc(task);
        assertEquals(proc.getProcId(), otherProc.getProcId());
        assertEquals(proc.getHostname(), otherProc.getHostname());
        assertEquals(proc.getNodeId(), otherProc.getNodeId());
        assertEquals(proc.getQuotaId(), otherProc.getQuotaId());
        assertEquals(proc.getTaskId(), otherProc.getTaskId());
    }

    public void testCreate() {

    }

    public void testDelete() {

    }

    public void testProcsByJob() {

    }

    public void testSetProcUnbooked() {

    }

}