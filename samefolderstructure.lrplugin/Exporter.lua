local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'
local LrDialogs = import 'LrDialogs'

Exporter = {}

function Exporter.splitDir(path)
    local r = {}
    local p = path
    while p ~= nil and string.len(p) > 0 do
        table.insert(r, LrPathUtils.leafName(p))
        -- LrDialogs.message("タイトル", LrPathUtils.leafName(p), "info")
        p = LrPathUtils.parent(p)
    end

    -- ドライブレターの:を削除
    r[#r] = string.sub(r[#r], 1, 1)
    -- ファイル名を削除
    table.remove(r, 1)

    return r
end

function Exporter.makePath(pathTbl)
    local result = ""
    local i = #pathTbl
    while i >= 1 do
        result = LrPathUtils.child(result, pathTbl[i])
        i = i - 1
    end
    return result
end

function Exporter.countDir(path)
    local folders = LrFileUtils.exists(path)
    local count = 0
    local lastDir = ""
    
    if folders then
        for dir in LrFileUtils.directoryEntries(path) do        
            if LrFileUtils.exists(dir) == "directory" then
                count = count + 1
                lastDir = dir
            end
        end
    end    
    return count, lastDir
end

function Exporter.getDirTillLastOneDir(path)
    local count = 1
    local nextDir = path 

    while count == 1 do
        local c, n = Exporter.countDir(nextDir)
        if c == 0 then
            break
        end
        count = c
        nextDir = n
    end

    return nextDir
end

function Exporter.export(functionContext, exportContext)
    local destDir = ""
    for i, rendition in exportContext:renditions() do
        -- レンダー待ち
        local success, pathOrMessage = rendition:waitForRender()
        if success then
            local photo = rendition.photo

            local originPath = photo:getRawMetadata('path')
            local destPath = rendition.destinationPath

            if destDir == "" then
                destDir = LrPathUtils.parent(destPath)
            end

            local folders = Exporter.splitDir(originPath)
            local makeDir = Exporter.makePath(folders)

            local fullMakeDir = LrPathUtils.child(LrPathUtils.parent(destPath), makeDir)

            local sDir, err = LrFileUtils.createAllDirectories(fullMakeDir)
            if sDir then
                LrFileUtils.move(destPath, LrPathUtils.child(fullMakeDir, LrPathUtils.leafName(destPath)))
            else
                -- ディレクトリの作成に失敗
                LrDialogs.message("エラー", err, "critical")
            end
        else
            -- エラーの処理を記述
        end
    end

    -- 2つ以上フォルダ、ファイルがあるまで検索
    local dir = Exporter.getDirTillLastOneDir(destDir)
    local _, toRemoveDir = Exporter.countDir(destDir)
    LrFileUtils.move(LrPathUtils.parent(dir), destDir)
    LrFileUtils.delete(toRemoveDir)
    
end