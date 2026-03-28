struct Button {
    private var title: String
    private var isOutlined: Bool = false
    
    public init(
        title: String
    ) {
        self.title = title
    }
    
    public func isOutlined(_ isOutlined: Bool) -> Self {
        var copy = self
        copy.isOutlined = isOutlined
        return copy
    }
}