import ModifierMacro

struct Button {
    private var title: String
    @Modifier private var isOutlined: Bool = false
    
    public init(
        title: String
    ) {
        self.title = title
    }
}