lib.addCommand('findoffsets', {
    help = 'Find offets for a shell',
    params = {
        {
            name = 'shell',
            type = 'string',
            help = 'name of the shell to test', 
        },
    },
    restricted = 'group.admin'
}, function(source, args, raw)
    TriggerClientEvent('nf_offset:client:testShell', source, args.shell)
end)

lib.addCommand('findoffsets:object', {
    help = 'Find object / prop offets for a shell',
    restricted = 'group.admin'
}, function(source, args, raw)
    TriggerClientEvent('nf_offset:client:objectOffsetMode', source)
end)