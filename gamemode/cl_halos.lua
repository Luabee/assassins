//CREDIT: MeepDarkness

function render.CreateOutlineData(length, passes, color)
    local step = length * 2 / 2 ^ (math.Round(passes) - 1)

    local matrices = {}

    for coord = -length, length, step do
        matrices[#matrices + 1] = Matrix()
        matrices[#matrices]:Translate(Vector(0, 0, coord))
        matrices[#matrices + 1] = Matrix()
        matrices[#matrices]:Translate(Vector(0, coord, 0))
        matrices[#matrices + 1] = Matrix()
        matrices[#matrices]:Translate(Vector(coord, 0, 0))
    end

    return {
        matrices = matrices,
        color = color or Color(255,255,255,255)
    }
end

function render.RenderOutline(prop, outlinedata)
    local matrices = outlinedata.matrices
    local color = outlinedata.color
    render.SetStencilEnable(true)
        render.ClearStencil()

        -- render.SetLightingMode(2)
        render.PushFilterMin(TEXFILTER.NONE)
        render.PushFilterMag(TEXFILTER.NONE)
        render.SuppressEngineLighting(true)

        render.SetStencilTestMask(255)
        render.SetStencilWriteMask(255)
        render.SetStencilCompareFunction(STENCIL_ALWAYS)
        render.SetStencilPassOperation(STENCIL_INCRSAT)
        render.SetStencilFailOperation(STENCIL_KEEP)
        render.SetStencilZFailOperation(STENCIL_KEEP)
        prop:DrawModel()

        render.SetStencilReferenceValue(0)
        render.SetStencilCompareFunction(STENCIL_EQUAL)
        render.SetStencilPassOperation(STENCIL_INVERT)

        for i = 1, #matrices do
            prop:EnableMatrix("RenderMultiply", matrices[i])

            prop:DrawModel()
        end
        prop:DisableMatrix("RenderMultiply")

        render.SuppressEngineLighting(false)
        render.PopFilterMag()
        render.PopFilterMin()
        -- render.SetLightingMode(0)

        render.SetStencilReferenceValue(255)
        render.SetStencilCompareFunction(STENCIL_EQUAL)
        render.SetStencilPassOperation(STENCIL_KEEP)
        cam.Start2D()
            surface.SetDrawColor(color)
            surface.DrawRect(0, 0, ScrW(), ScrH())
        cam.End2D()
    render.SetStencilEnable(false)

end

-- local data = render.CreateOutlineData(0.2, 1, Color(255,0,0,255))

/*
hook.Add("PreDrawOpaqueRenderables", "ass_halos", function()

    local prop = LocalPlayer():GetEyeTraceAutoPilot().Entity

    if (not IsValid(prop)) then
        return
    end

    cam.Start3D()
    -- [[
    local t = SysTime
    local d = t()]]
        render.RenderOutline(prop, data)
        -- [[
    print(t()-d)
    d = t()
        halo.Render{
            Ents = {prop},
            Color = Color(255,0,0,255),
            BlurX = 2,
            BlurY = 2,
            DrawPasses =  1,
            Additive = false,
            IgnoreZ = false
        }
    print("halo",t()-d)
    ]]
    cam.End3D()



end)
*/
