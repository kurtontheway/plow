

#######################
# LayerStats
#
cdef LayerStats initLayerStats(LayerStatsT& t):
    cdef LayerStats stats = LayerStats()
    stats.setLayerStats(t)
    return stats


cdef class LayerStats:
    """
    Data structure representing stats for a Layer

    :var highRam: int
    :var avgRam: int
    :var stdDevRam: float
    :var highCores: float
    :var avgCores: float
    :var stdDevCores: float
    :var highCoreTime: int
    :var avgCoreTime: int
    :var lowCoreTime: int
    :var stdDevCoreTime: float
    :var totalCoreTime: long
    :var totalSuccessCoreTime: long
    :var totalFailCoreTime: long

    """
    cdef LayerStatsT _stats

    cdef setLayerStats(self, LayerStatsT& t):
        self._stats = t 

    property highRam:
        def __get__(self): return self._stats.highRam
    
    property avgRam:
        def __get__(self): return self._stats.avgRam
    
    property stdDevRam:
        def __get__(self): return self._stats.stdDevRam
    
    property highCores:
        def __get__(self): return self._stats.highCores
    
    property avgCores:
        def __get__(self): return self._stats.avgCores
    
    property stdDevCores:
        def __get__(self): return self._stats.stdDevCores
    
    property highCoreTime:
        def __get__(self): return self._stats.highCoreTime
    
    property avgCoreTime:
        def __get__(self): return self._stats.avgCoreTime
    
    property lowCoreTime:
        def __get__(self): return self._stats.lowCoreTime
    
    property stdDevCoreTime:
        def __get__(self): return self._stats.stdDevCoreTime
    
    property totalCoreTime:
        def __get__(self): return long(self._stats.totalCoreTime)
    
    property totalSuccessCoreTime:
        def __get__(self): return long(self._stats.totalSuccessCoreTime)
    
    property totalFailCoreTime:
        def __get__(self): return long(self._stats.totalFailCoreTime)


#######################
# Layers
#
cdef LayerSpec initLayerSpec(LayerSpecT& t):
    cdef LayerSpec spec = LayerSpec()
    spec.setLayerSpec(t)
    return spec

cdef class LayerSpec:
    """
    Defines a new layer 

    :var name: str
    :var range: str 
    :var chunk: int 
    :var minCores: int 
    :var maxCores: int 
    :var minRam: int 
    :var threadable: bool
    :var command: list[str]
    :var depends: list[:class:`.DependSpec`] 
    :var tasks: list [:class:`.TaskSpec`]
    :var tags: list(str)
    :var env: dict

    """
    cdef public string name
    cdef public int chunk, minCores, maxCores, minRam
    cdef public bint threadable
    cdef list command, depends, tasks 
    cdef list tags
    cdef string range
    cdef dict env
    cdef _LayerSpecT__isset __isset

    def __init__(self, **kwargs):
        self.name = kwargs.get('name', '')
        self.chunk = kwargs.get('chunk', 0)
        self.minCores = kwargs.get('minCores', 0)
        self.maxCores = kwargs.get('maxCores', 0)
        self.minRam = kwargs.get('minRam', 0)
        self.threadable = kwargs.get('threadable', False) 
        self.command = kwargs.get('command', [])
        self.depends = kwargs.get('depends', [])
        self.tasks = kwargs.get('tasks', [])
        self.tags = kwargs.get('tags', list())
        self.env = kwargs.get('env', {})

        if 'range' in kwargs:
            self.range = kwargs.get('range', '')
            self.__isset.range = True


    def __repr__(self):
        return "<LayerSpec: %s>" % self.name

    cdef setLayerSpec(self, LayerSpecT& t):
        self.name  = t.name 
        self.range = t.range
        self.chunk = t.chunk
        self.minCores = t.minCores
        self.maxCores = t.maxCores
        self.minRam = t.minRam
        self.threadable = t.threadable
        self.command = t.command
        self.tags = t.tags
        self.env = t.env

        self.__isset = t.__isset

        cdef DependSpecT dep
        self.depends = [initDependSpec(dep) for d in t.depends]

        cdef TaskSpecT task
        self.tasks = [initTaskSpec(task) for task in t.tasks]

    cdef LayerSpecT toLayerSpecT(self):
        cdef LayerSpecT s

        s.name = self.name 
        s.range = self.range
        s.chunk = self.chunk
        s.minCores = self.minCores
        s.maxCores = self.maxCores
        s.minRam = self.minRam
        s.threadable = self.threadable
        s.command = self.command
        s.tags = self.tags
        s.env = self.env
        
        s.__isset = self.__isset

        cdef: 
            DependSpecT dSpecT
            DependSpec dSpec
        for dSpec in self.depends:
            dSpecT = dSpec.toDependSpecT()
            s.depends.push_back(dSpecT) 

        cdef: 
            TaskSpecT tSpecT
            TaskSpec tSpec
        for tSpec in self.tasks:
            tSpecT = tSpec.toTaskSpecT()
            s.tasks.push_back(tSpecT) 

        return s

    property range:
        def __get__(self): return self.range
        def __set__(self, val): 
            self.range = val
            self.__isset.range = True

    property command:
        def __get__(self): return self.command
        def __set__(self, val): self.command = val

    property depends:
        def __get__(self): return self.depends
        def __set__(self, val): self.depends = val

    property tasks:
        def __get__(self): return self.tasks
        def __set__(self, val): self.tasks = val

    property tags:
        def __get__(self): return self.tags
        def __set__(self, val): self.tags = val

    property env:
        def __get__(self): return self.env
        def __set__(self, val): self.env = val


cdef inline Layer initLayer(LayerT& l):
    cdef Layer layer = Layer()
    layer.setLayer(l)
    return layer


cdef class Layer:
    """
    Represents an existing layer 

    :var id: str
    :var name: str
    :var range: str
    :var chunk: int
    :var minCores: int
    :var maxCores: int
    :var runCores: int
    :var minRam: int
    :var maxRam: int
    :var threadable: bool
    :var totals: list[:class:`.TaskTotals`]
    :var tags: list(str)
    :var stats: :class:`.LayerStats`
    
    """
    cdef:
        LayerT _layer 
        TaskTotals _totals
        LayerStats _stats

    def __init__(self):
        self._totals = None

    def __repr__(self):
        return "<Layer: %s>" % self.name

    cdef setLayer(self, LayerT& l):
        self._layer = l
        self._totals = initTaskTotals(self._layer.totals)
        self._stats = initLayerStats(self._layer.stats)

    property id:
        def __get__(self): return self._layer.id

    property name:
        def __get__(self): return self._layer.name

    property range:
        def __get__(self): return self._layer.range

    property chunk:
        def __get__(self): return self._layer.chunk

    property minCores:
        def __get__(self): return self._layer.minCores

    property maxCores:
        def __get__(self): return self._layer.maxCores

    property runCores:
        def __get__(self): return self._layer.runCores

    property minRam:
        def __get__(self): return self._layer.minRam

    property maxRam:
        def __get__(self): return self._layer.maxRam

    property threadable:
        def __get__(self): return self._layer.threadable

    property totals:
        def __get__(self): return self._totals

    property tags:
        def __get__(self): return self._layer.tags

    property stats:
        def __get__(self): return self._stats

    @reconnecting
    def refresh(self):
        """
        Refresh the attributes from the server
        """
        cdef LayerT layer 
        conn().proxy().getLayerById(layer, self._layer.id)
        self.setLayer(layer)

    def get_outputs(self):
        """ :returns: list[:class:`.Output`] """
        return get_layer_outputs(self)

    def add_output(self, string path, Attrs& attrs):
        """
        Add an output to the layer 

        :param path: str 
        :param attrs: dict
        """
        add_layer_output(self, path, attrs)

    def set_tags(self, vector[string]& tags):
        """
        Set the tags for the layer 

        :param tags: list(str)
        """
        set_layer_tags(self, tags)
        self._layer.tags = tags

    def set_threadable(self, bint threadable):
        """ :param threadable: bool """
        set_layer_threadable(self, threadable)
        self._layer.threadable = threadable

    def set_min_cores_per_task(self, int minCores):
        """ :param minCores: int """
        set_layer_min_cores_per_task(self, minCores)
        self._layer.minCores = minCores

    def set_max_cores_per_task(self, int maxCores):
        """ :param maxCores: int """
        set_layer_max_cores_per_task(self, maxCores)
        self._layer.maxCores = maxCores

    def set_min_ram_per_task(self, int minRam):
        """ :param minRam: int """
        set_layer_min_ram_per_task(self, minRam)
        self._layer.minRam = minRam

    def get_depends(self):
        """
        Get a list of depends that others have 
        on this layer

        :returns: list[:class:`.Depend`]
        """
        cdef list ret = get_depends_on_layer(self)
        return ret 

    def get_depends_on(self):
        """
        Get a list of depends this layer has on others

        :returns: list[:class:`.Depend`]
        """
        cdef list ret = get_layer_depends_on(self)
        return ret

@reconnecting
def get_layer_by_id(Guid& layerId):
    """
    Get a layer by its id 

    :param layerId: str 
    :returns: :class:`.Layer`
    """
    cdef:
        LayerT layerT 
        Layer layer

    try:
        conn().proxy().getLayerById(layerT, layerId)
    except RuntimeError:
        return None 

    layer = initLayer(layerT)
    return layer

@reconnecting
def get_layer(Job job, string name):
    """
    Get layer by its name

    :param job: :class:`.Job`
    :param name: str 
    :returns: :class:`.Layer`
    """
    cdef:
        LayerT layerT 
        Layer layer

    try:
        conn().proxy().getLayer(layerT, job.id, name)
    except RuntimeError, e:
        if str(e) in EX_CONNECTION:
            raise
        return None

    layer = initLayer(layerT)
    return layer

@reconnecting
def get_layers(Job job):
    """
    Get layers by a job id 

    :param job: :class:`.Job`
    :returns: list[:class:`.Layer`]
    """
    cdef:
        LayerT layerT 
        Layer layer
        vector[LayerT] layers 
        list ret

    try:
        conn().proxy().getLayers(layers, job.id)
    except RuntimeError, e:
        if str(e) in EX_CONNECTION:
            raise
        ret = []
        return ret

    ret = [initLayer(layerT) for layerT in layers]
    return ret

def add_layer_output(Layer layer, string path, Attrs& attrs):
    """
    A an output to a layer 

    :param layer: :class:`.Layer`
    :param path: str 
    :param attrs: dict
    """
    conn().proxy().addOutput(layer.id, path, attrs)

@reconnecting
def get_layer_outputs(Layer layer):
    """
    Get the outputs for a layer 

    :param layer: :class:`.Layer`
    :returns: list[:class:`.Layer`]
    """
    cdef:
        vector[OutputT] outputs
        OutputT outT 
        Output output 
        list ret 

    try:
        conn().proxy().getLayerOutputs(outputs, layer.id)
    except RuntimeError, e:
        if str(e) in EX_CONNECTION:
            raise
        ret = []
        return ret 

    ret = [initOutput(outT) for outT in outputs]
    return ret

@reconnecting
def set_layer_tags(Layer layer, vector[string]& tags):
    """ 
    :param layer: :class:`.Layer`
    :param tags: list(str) 
    """
    conn().proxy().setLayerTags(layer.id, tags)

@reconnecting
def set_layer_min_cores_per_task(Layer layer, int minCores):
    """ 
    :param layer: :class:`.Layer`
    :param minCores: int 
    """
    conn().proxy().setLayerMinRamPerTask(layer.id, minCores)

@reconnecting
def set_layer_max_cores_per_task(Layer layer, int maxCores):
    """ 
    :param layer: :class:`.Layer`
    :param maxCores: int 
    """
    conn().proxy().setLayerMaxCoresPerTask(layer.id, maxCores)

@reconnecting
def set_layer_min_ram_per_task(Layer layer, int minRam):
    """ 
    :param layer: :class:`.Layer`
    :param minRam: int 
    """
    conn().proxy().setLayerMinRamPerTask(layer.id, minRam)

@reconnecting
def set_layer_threadable(Layer layer, bint threadable):
    """ 
    :param layer: :class:`.Layer`
    :param threadable: bool
    """
    conn().proxy().setLayerThreadable(layer.id, threadable)


