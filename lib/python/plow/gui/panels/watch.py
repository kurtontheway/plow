"""
The render job watch panel allows you to 
   1. setup filters to automatically load jobs. (defaults to loading your jobs)
   2. individually add jobs you want to watch.
"""
import os
import logging
from functools import partial

import plow.client
from plow.client import JobState

from plow.gui.manifest import QtCore, QtGui
from plow.gui.panels import Panel
from plow.gui.common.widgets import CheckableListBox, BooleanCheckBox, SpinSliderWidget, ManagedListWidget
from plow.gui.common.job import JobProgressBar, JobSelectionDialog, JobStateWidget
from plow.gui import constants 
from plow.gui.util import formatMaxValue, formatDateTime, formatDuration
from plow.gui.event import EventManager


LOGGER = logging.getLogger(__name__)


JOBID_ROLE = QtCore.Qt.UserRole
JOB_ROLE = QtCore.Qt.UserRole + 1

class RenderJobWatchPanel(Panel):

    def __init__(self, name="Render Watch", parent=None):
        Panel.__init__(self, name, "Render Watch", parent)

        # Setup the default configuration
        self.setAttr("loadMine", True)
        self.setAttr("projects", [])
        self.setAttr("allProjects", True)
        self.setAttr("refreshSeconds", 5)
        self.setAttr("users", [])

        self.setWidget(RenderJobWatchWidget(self.attrs, self))
        self.setWindowTitle(name)

    def init(self):
        # TODO
        # sweep button (remove finished)
        # refresh button
        # seperator
        # kill button (multi-select)
        # comment button (multi-select)
        # 
        self.titleBarWidget().addAction(
            QtGui.QIcon(":/load.png"), "Load", self.openLoadDialog)

        self.titleBarWidget().addAction(
            QtGui.QIcon(":/sweep.png"), "Remove Finished Jobs", self.removeFinishedJobs)

    def openLoadDialog(self):
        dialog = JobSelectionDialog()
        if dialog.exec_():
            [self.widget().addJob(job) for job in dialog.getSelectedJobs()]

    def _openPanelSettingsDialog(self):
        d = RenderJobWatchSettingsDialog(self.attrs)
        if d.exec_():
            self.attrs.update(d.getAttrs())
            self.setRefreshTime(self.attrs["refreshSeconds"])

    def removeFinishedJobs(self):
         self.widget().removeFinishedJobs()

    def refresh(self):
        self.widget().refresh()

class RenderJobWatchWidget(QtGui.QWidget):

    Header = ["Job", "State", "Run", "Wait", "Min", "Max", "Duration", "Progress"]
    Width = [400, 75, 60, 60, 60, 60, 100, 250]

    def __init__(self, attrs, parent=None):
        QtGui.QWidget.__init__(self, parent)
        QtGui.QVBoxLayout(self)
        self.attrs = attrs
        self.__jobs = { }

        self.__tree = QtGui.QTreeWidget(self)
        self.__tree.setHeaderLabels(self.Header)
        self.__tree.setColumnCount(len(self.Header))
        self.__tree.setUniformRowHeights(True)
        self.__tree.viewport().setFocusPolicy(QtCore.Qt.NoFocus)
        [self.__tree.setColumnWidth(i, v) for i, v in enumerate(self.Width)]
        self.__tree.itemDoubleClicked.connect(self.__itemDoubleClicked)
        self.__tree.setContextMenuPolicy(QtCore.Qt.CustomContextMenu)
        self.__tree.customContextMenuRequested.connect(self.__showContextMenu)

        def treeMousePress(event):
            item = self.__tree.itemAt(event.pos())
            if not item:
                self.__tree.clearSelection()
            QtGui.QTreeWidget.mousePressEvent(self.__tree, event)

        self.__tree.mousePressEvent = treeMousePress

        self.layout().addWidget(self.__tree)

    def refresh(self):
        self.__updateExistingJobs()
        self.__findNewJobs()

    def addJob(self, job):
        if self.__jobs.has_key(job.id):
            return False

        item = QtGui.QTreeWidgetItem([
            job.name,
            "",
            "%02d" % job.totals.running,
            "%02d" % job.totals.waiting,
            "%02d" % job.minCores,
            formatMaxValue(job.maxCores),
            formatDuration(job.startTime, job.stopTime)
        ])

        self.__jobs[job.id] = item

        item.setToolTip(6, "Started: %s\nStopped:%s" % 
            (formatDateTime(job.startTime), formatDateTime(job.stopTime)))

        item.setData(0, JOBID_ROLE, job.id)
        item.setData(0, JOB_ROLE, job)

        self.__tree.addTopLevelItem(item)

        progress = JobProgressBar(job.totals, self.__tree)
        self.__tree.setItemWidget(item, len(self.Header)-1, progress);

        self.__setJobStateAndColor(item)
        # state = JobStateWidget(job.state, job.totals.dead, self)
        # self.__tree.setItemWidget(item, 1, state)

        return True

    def updateJob(self, job):
        item = self.__jobs[job.id]
        item.setData(0, JOB_ROLE, job)

        item.setText(2, "%02d" % job.totals.running)
        item.setText(3, "%02d" % job.totals.waiting)
        item.setText(4, "%02d" % job.minCores)
        item.setText(5, formatMaxValue(job.maxCores))
        item.setText(6, formatDuration(job.startTime, job.stopTime))
        item.setToolTip(6, "Started: %s\nStopped:%s" % 
            (formatDateTime(job.startTime), formatDateTime(job.stopTime)))

        self.__tree.itemWidget(item, len(self.Header)-1).setTotals(job.totals)
        # self.__tree.itemWidget(item, 1).setState(job.state, job.totals.dead)
        self.__setJobStateAndColor(item)

    def removeFinishedJobs(self):
        finished = []
        for item in self.__jobs.itervalues():
            if item.data(0, JOB_ROLE).state == JobState.FINISHED:
                finished.append(item)
        [self.removeJobItem(item) for item in finished]

    def removeJobItem(self, item):
        jobid = str(item.data(0, JOBID_ROLE))
        try:
            del self.__jobs[jobid]
        except Exception, e:
            print e
        idx = self.__tree.indexOfTopLevelItem(item)
        self.__tree.takeTopLevelItem(idx)

    def __updateJobs(self, jobs):
        for job in jobs:
            if not self.__jobs.has_key(job.id):
                self.addJob(job)
            else:
                self.updateJob(job)

    def __updateExistingJobs(self):
        FINISHED = JobState.FINISHED
        req = { }
        req["matchingOnly"] = True
        req["jobIds"] = [jobId for jobId, item in self.__jobs.iteritems() 
            if item.data(0, JOB_ROLE).state != FINISHED]
        self.__updateJobs(plow.client.get_jobs(**req))

    def __findNewJobs(self):
        req = { }
        req["matchingOnly"] = True
        req["user"] = []
        req["states"] = [JobState.RUNNING]
        if self.attrs["loadMine"]:
            req["user"].append(os.environ["USER"])
        if self.attrs["users"]:
            req["user"].extend(self.attrs["users"])
        if self.attrs["projects"]:
            req["projects"] = self.attrs["projects"]
        self.__updateJobs(plow.client.get_jobs(**req))

    def __showContextMenu(self, pos):
        tree = self.__tree
        item = tree.itemAt(pos)
        job = item.data(0, JOB_ROLE)

        menu = QtGui.QMenu(tree)
        pause = menu.addAction("Un-Pause" if job.paused else "Pause")
        kill = menu.addAction("Kill")
        eat = menu.addAction("Eat Dead")
        retry = menu.addAction("Retry Dead")

        pause.triggered.connect(partial(job.pause, not job.paused))

        eat.setEnabled(bool(job.totals.dead))
        eat.triggered.connect(partial(self.__eatDeadTasks, job))

        retry.setEnabled(bool(job.totals.dead))
        retry.triggered.connect(partial(self.__retryDeadTasks, job))

        kill.setEnabled(bool(job.totals.running))
        kill.triggered.connect(partial(job.kill, "plow-wrangler"))

        menu.popup(tree.mapToGlobal(pos))

    def __setJobStateAndColor(self, item):
        job = item.data(0, JOB_ROLE)
        totals = job.totals

        color = QtCore.Qt.black 

        if job.paused:
            bgcolor = constants.BLUE
            color = QtCore.Qt.white
            text = "PAUSED"

        elif totals.dead:
            if totals.running:
                text = "RUNNING"
            else:
                text = "DEAD"
            bgcolor = constants.RED 

        else:
            bgcolor = constants.COLOR_JOB_STATE[job.state]
            text = constants.JOB_STATES[job.state]

        item.setText(1, text)
        item.setBackground(1, bgcolor)
        item.setForeground(1, color)

    def __itemDoubleClicked(self, item, col):
        uid = item.data(0, JOBID_ROLE)
        EventManager.emit("JOB_OF_INTEREST", uid)

    def __eatDeadTasks(self, job):
        tasks = plow.client.get_tasks(job=job)
        dead = [t for t in tasks if t.state == plow.client.TaskState.DEAD]
        if dead:
            LOGGER.info("Eating %d tasks", len(dead))
            plow.client.eat_tasks(task=dead)

    def __retryDeadTasks(self, job):
        tasks = plow.client.get_tasks(job=job)
        dead = [t for t in tasks if t.state == plow.client.TaskState.DEAD]
        if dead:
            LOGGER.info("Retrying %d tasks", len(dead))
            plow.client.retry_tasks(task=dead)


class RenderJobWatchSettingsDialog(QtGui.QDialog):
    """
    A dialog box that lets you configure how the render job widget.
    """
    def __init__(self, attrs, parent=None):
        QtGui.QDialog.__init__(self, parent)
        layout = QtGui.QVBoxLayout(self)

        self.sliderRefresh = SpinSliderWidget(1, 60, attrs["refreshSeconds"], self)
        self.sliderRefresh.slider.setTickInterval(5)
        self.sliderRefresh.slider.setTickPosition(QtGui.QSlider.TicksBelow)
        self.checkboxLoadMine = BooleanCheckBox(bool(attrs["loadMine"]))
        self.listUsers = ManagedListWidget(attrs["users"], "name", self)
        self.checkboxLoadErrors = QtGui.QCheckBox(self)

        projects = [project.code for project in plow.client.get_projects()]
        self.listProjects = CheckableListBox("Projects", projects,
            attrs["projects"], bool(attrs["allProjects"]), self)

        group_box1 = QtGui.QGroupBox("Auto Load Jobs", self)

        form_layout1 = QtGui.QFormLayout(group_box1)
        form_layout1.addRow("Refresh", self.sliderRefresh)
        form_layout1.addRow("Load Mine:", self.checkboxLoadMine)
        form_layout1.addRow("Load User:", self.listUsers)
        form_layout1.addRow("Load With Errors:", self.checkboxLoadErrors)

        # move to project multi-select widget
        group_box2 = QtGui.QGroupBox("Filters", self)
        form_layout2 = QtGui.QFormLayout(group_box2)
        form_layout2.addRow("For Projects:", self.listProjects)

        buttons = QtGui.QDialogButtonBox(QtGui.QDialogButtonBox.Ok | QtGui.QDialogButtonBox.Cancel);
        buttons.accepted.connect(self.accept)
        buttons.rejected.connect(self.reject)

        layout.addWidget(group_box1)
        layout.addWidget(group_box2)
        layout.addWidget(buttons)

    def getAttrs(self):


        return {
            "refreshSeconds": self.sliderRefresh.value(),
            "loadMine": self.checkboxLoadMine.isChecked(),
            "users": self.listUsers.getValues(),
            "projects": self.listProjects.getCheckedOptions(),
            "allProjects": self.listProjects.isAllSelected()
        }

