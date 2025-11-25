local NetworkDefines = {}

--同步模式枚举
NetworkDefines.SyncMode =  { 
    Observers = 1, --同步给观察者
    Owner = 2 --同步给自己
}
--同步路径枚举
NetworkDefines.SyncDirection = { 
    ServerToClient = 1,
    ClientToServer = 2
}
--可见性枚举
NetworkDefines.Visibility = { 
    Default = 1, 
    ForceHidden = 2, 
    ForceShown = 3, 
}

return NetworkDefines