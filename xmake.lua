add_rules("mode.debug", "mode.release")

-- 1. เพิ่ม Repo (ใช้ตัวเดียวกับ MagnusMod ที่บิ้วผ่าน)
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

    -- ดึงกฎการบิ้วของ LeviLamina
    add_rules("@levibuildscript/linkrule")
    add_rules("@levibuildscript/modpacker")

    -- รวม Package เข้าเป้าหมาย
    add_packages("levilamina", "levibuildscript")

    -- [หัวใจสำคัญ] แก้ปัญหา Path หลอนด้วยการฉีด Path ทุกจุดที่น่าจะเป็นไปได้
    on_load(function (target)
        import("core.project.project")
        local pkg = target:pkg("levilamina")
        if pkg then
            local installdir = pkg:installdir()
            -- เช็คทั้งโฟลเดอร์ include และ src (เพราะบางรุ่นไฟล์อยู่คนละที่)
            for _, sub in ipairs({"include", "src", "src-server"}) do
                local incdir = path.join(installdir, sub)
                if os.isdir(incdir) then
                    target:add("includedirs", incdir, {public = true})
                    -- ใช้ /I เพื่อบังคับ Compiler MSVC ให้มองเป็น Internal Header
                    target:add("cxflags", "/I" .. incdir)
                    print(">>> Injected Include Path: " .. incdir)
                end
            end
        end
    end)

    -- Flags มาตรฐานสำหรับ MSVC และ LeviLamina
    add_cxflags("/EHa", "/utf-8", "/W4")
    add_defines("NOMINMAX", "UNICODE", "_SILENCE_ALL_CXX17_DEPRECATION_WARNINGS")
    add_defines("ENTT_PACKED_PAGE=128", "ENTT_SPARSE_PAGE=2048", "ENTT_NO_MIXIN", "LL_PLAT_S")

    -- จัดการไฟล์ในโปรเจกต์
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