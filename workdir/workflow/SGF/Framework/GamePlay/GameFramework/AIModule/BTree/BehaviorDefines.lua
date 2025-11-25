local BehaviorDefines = {}

--事件类型
BehaviorDefines.EEvent = {
    INTERRUPTED = "Interrupted",           -- 行为树被中断
    BEFORE_RUN = "BeforeRun",              -- 行为树开始执行前
    AFTER_RUN = "AfterRun",                -- 行为树执行完成后
    AFTER_RUN_SUCCESS = "AfterRunSuccess", -- 行为树执行成功后
    AFTER_RUN_FAILURE = "AfterRunFailure", -- 行为树执行失败后
}

--结果类型
BehaviorDefines.EResult = {
    FAIL    = "FAIL",       --失败
    SUCCESS = "SUCCESS",    --成功
    RUNNING = "RUNNING",    --正在运行
    ABORT   = "ABORT",      --中断
}

return BehaviorDefines