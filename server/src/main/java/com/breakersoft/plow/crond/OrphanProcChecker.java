package com.breakersoft.plow.crond;

import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;

import com.breakersoft.plow.Task;
import com.breakersoft.plow.dispatcher.DispatchService;
import com.breakersoft.plow.dispatcher.domain.DispatchProc;
import com.breakersoft.plow.service.JobService;
import com.breakersoft.plow.thrift.TaskState;

/**
 *
 * Cleans up orphaned procs.
 *
 * @author chambers
 *
 */
public class OrphanProcChecker {

    private static final Logger logger = LoggerFactory.getLogger(OrphanProcChecker.class);

    @Autowired
    DispatchService dispatchService;

    @Autowired
    JobService jobService;

    public void execute() {
        final List<DispatchProc> procs = dispatchService.getOrphanProcs();
        logger.info("Orphan proc checker found {} orphan procs.", procs.size());

        for (DispatchProc proc: procs) {

            if (proc.getTaskId() != null) {
                final Task task = jobService.getTask(proc.getTaskId());
                logger.warn("Found orphaned {}", task);
                dispatchService.stopTask(task, TaskState.WAITING);
            }

            logger.warn("Deallocating orphan {}", proc);
            dispatchService.deallocateProc(proc, "orphaned");
        }
    }
}
