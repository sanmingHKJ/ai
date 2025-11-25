local BehaviorProcess = {
    Parallel = GFScript("AIModule.BTree.Composites.Parallel"),
    Selector = GFScript("AIModule.BTree.Composites.Selector"),
    Sequence = GFScript("AIModule.BTree.Composites.Sequence"),

    Once = GFScript("AIModule.BTree.Decorators.Once"),
    Not = GFScript("AIModule.BTree.Decorators.Not"),
    ListenTree = GFScript("AIModule.BTree.Decorators.ListenTree"),
    AlwaysFail = GFScript("AIModule.BTree.Decorators.AlwaysFail"),
    AlwaysSuccess = GFScript("AIModule.BTree.Decorators.AlwaysSuccess"),
    RepeatUntilSuccess = GFScript("AIModule.BTree.Decorators.RepeatUntilSuccess"),
    RepeatUntilFailure = GFScript("AIModule.BTree.Decorators.RepeatUntilFail"),
    Compare = GFScript("AIModule.BTree.Decorators.Compare"),
    Check = GFScript("AIModule.BTree.Decorators.Check"),
  
    Log  = GFScript("AIModule.BTree.Actions.Log"),
    Wait = GFScript("AIModule.BTree.Actions.Wait"),
}

return BehaviorProcess