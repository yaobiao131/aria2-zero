rule("merge_staticlib")
    after_link(function (target, opt)
        if not target:is_static() then
            return
        end
        import("utils.archive.merge_staticlib")
        import("core.project.depend")
        import("utils.progress")
        local library_set = {}
        for name, pkg in pairs(target:pkgs()) do
            local libfiles = pkg:libraryfiles()
            for _, libfile in ipairs(libfiles) do
                if libfile:endswith(".a") or libfile:endswith(".lib") then
                    library_set[libfile] = 1
                end
            end
        end
        -- 支持合并依赖的静态库
        for _, dep in ipairs(target:orderdeps()) do
            if dep:is_static() then
                library_set[dep:targetfile()] = 1
            end
        end
        local libraryfiles = table.keys(library_set)
        if #libraryfiles > 0 then
            table.insert(libraryfiles, target:targetfile())
        end
        depend.on_changed(function ()
            progress.show(opt.progress, "${color.build.target}merge_staticlib.$(mode) %s", path.filename(target:targetfile()))
            if #libraryfiles > 0 then
                local tmpfile = os.tmpfile() .. path.extension(target:targetfile())
                merge_staticlib(target, tmpfile, libraryfiles)
                os.cp(tmpfile, target:targetfile())
                os.rm(tmpfile)
            end
        end, {dependfile = target:dependfile(target:targetfile() .. ".merge_staticlib"), files = libraryfiles, changed = target:is_rebuilt()})
    end)
