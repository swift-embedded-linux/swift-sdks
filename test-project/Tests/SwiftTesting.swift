#if canImport(Testing)
    import Testing

    @Test
    func mySimpleTest() {
        #expect(1 == 1, "One is equal to one")
    }
#endif
