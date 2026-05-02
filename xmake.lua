add_rules("mode.debug", "mode.release")

-- 1. เพิ่ม Repo
add_repositories("levimc-repo https://github.com/LiteLDev/xmake-repo.git")

-- 2. กำหนด Dependencies
add_requires("levibuildscript")

if is_config("target_type", "server") then
    add_requires("levilamina 26.10.9", {configs = {target_type = "server"}})
else
    add_requires("levilamina 26.10.9", {configs = {target_type = "client"}})
end

-- ตั้งค่าตัวเลือกการบิ้ว
option("target_type")
    set_default("server")
    set_showmenu(true)
    set_values("server", "client")
option_end()

target("WorldX")
    set_version("0.1.0")
    set_targetdir("bin")
    set_kind("shared")
    set_languages("c++20")
    set_symbols("debug")
    set_runtimes("MD")

    -- [จุดที่แก้] ใช้การเช็คแบบ Xmake Native เพื่อป้องกัน Error
    on_load(function (target)
        import("core.project.project")

        -- 1. ฉีด Include Path (เพื่อให้ผ่าน C1083)
        local pkg = target:pkg("levilamina")
        if pkg then
            local installdir = pkg:installdir()
            for _, sub in ipairs({"include", "src", "src-server"}) do
                local incdir = path.join(installdir, sub)
                if os.isdir(incdir) then
                    target:add("includedirs", incdir, {public = true})
                    target:add("cxflags", "/I" .. incdir)
                end
            end
        end

        -- 2. จัดการเรื่อง Version (เช็คดื้อๆ เลยว่ามีโฟลเดอร์ .git ไหม)
        local mod_version = target:version()
        local git_dir = path.join(os.projectdir(), ".git")

        if os.isdir(git_dir) then
            -- ถ้ามี git ให้ดึง hash มาต่อท้าย
            local hash = os.iorun("git rev-parse --short HEAD"):trim()
            if hash then
                mod_version = mod_version .. "+" .. hash
            end
        end

        -- โหลด Rules
        target:add("rules", "@levibuildscript/linkrule")
        target:add("rules", "@levibuildscript/modpacker", { modVersion = mod_version })
    end)

    -- รวม Package
    add_packages("levilamina", "levibuildscript")

    -- Flags & Defines
    add_cxflags("/EHa", "/utf-8", "/W4")
    add_defines("NOMINMAX", "UNICODE", "_SILENCE_ALL_CXX17_DEPRECATION_WARNINGS")
    add_defines("ENTT_PACKED_PAGE=128", "ENTT_SPARSE_PAGE=2048", "ENTT_NO_MIXIN", "LL_PLAT_S")

    -- ไฟล์ในโปรเจกต์
    add_headerfiles("src/**.h")
    add_files("src/**.cpp")
    add_includedirs("src")

    -- Post-build (Copy DLLs)
    after_build(function (target)
        import("core.project.project")
        local count = 0
        for _, pkg in ipairs(target:orderpkgs()) do
            for _, search_dir in ipairs({pkg:installdir("bin"), pkg:installdir("lib")}) do
                if search_dir and os.isdir(search_dir) then
                    for _, file in ipairs(os.files(path.join(search_dir, "*.dll"))) do
                        local filename = path.filename(file)
                        if filename:lower() ~= "levilamina.dll" then
                            local dest = path.join(target:targetdir(), "WorldX", filename)
                            if not os.isfile(dest) or os.filesize(file) ~= os.filesize(dest) then
                                os.mkdir(path.directory(dest))
                                os.cp(file, dest)
                                print("  -> Copied: " .. filename)
                                count = count + 1
                            end
                        end
                    end
                end
            end
        end
        if count > 0 then
            print("======== DONE ========")
            print("Total DLLs copied: " .. count)
        end
    end)