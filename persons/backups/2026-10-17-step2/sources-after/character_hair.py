"""Deterministic, sculpted hair volumes in the character generator's rest space.

Public API: build_hair('boaz' | 'ravi', mesh_callback).
The callback has build_characters.mesh's signature; all vertices belong to head.
No Blender dependency: geometry and triangle budgets can be inspected in Python.
Geometry stays below z=1.125, the original Boaz hair silhouette's upper bound.
"""
import math


def _add(a, b): return tuple(x+y for x, y in zip(a, b))
def _sub(a, b): return tuple(x-y for x, y in zip(a, b))
def _mul(a, n): return tuple(x*n for x in a)
def _dot(a, b): return sum(x*y for x, y in zip(a, b))
def _cross(a, b): return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])
def _unit(a): return _mul(a, 1/max(math.sqrt(_dot(a, a)), 1e-12))
def _mix(a, b, t): return _add(_mul(a, 1-t), _mul(b, t))


def _bezier(points, t):
    a, b, c, d = points
    u = 1-t
    return tuple(u**3*a[i]+3*u*u*t*b[i]+3*u*t*t*c[i]+t**3*d[i] for i in range(3))


def clump_geometry(points, width, depth, outward, twist=0., sections=10, sides=10):
    """Closed curved leaf/lens volume with unequal shoulders and a swept tip.

    A broad flattened lenticular section avoids the old round noodle shape.
    Roots are tucked into the scalp; the single end vertex forms a clean tip.
    Frames use the supplied scalp normal and parallel-direction projection.
    """
    verts = []
    for j in range(sections):
        t = j/sections
        p = _bezier(points, t)
        tangent = _unit(_sub(_bezier(points, min(1., t+.001)), _bezier(points, max(0., t-.001))))
        normal = _unit(_sub(outward, _mul(tangent, _dot(outward, tangent))))
        across = _unit(_cross(normal, tangent))
        # Short broad body, deliberate shoulder, long narrow end. No constant radii.
        shape = (.36+.85*math.sin(math.pi*(t*.90+.03))) * (1-t)**.52
        roll = twist*math.sin(math.pi*t)
        across, normal = (_add(_mul(across, math.cos(roll)), _mul(normal, math.sin(roll))),
                          _add(_mul(normal, math.cos(roll)), _mul(across, -math.sin(roll))))
        for k in range(sides):
            a = 2*math.pi*k/sides
            # Upper ridge softens into two broad shoulders; underside remains buried.
            w = math.cos(a)*width*shape
            h = math.sin(a)*depth*shape*(1+.12*math.cos(2*a))
            v = _add(p, _add(_mul(across, w), _mul(normal, h)))
            # Ease the highest crown gently below the preserved height cap.
            # A hard clamp would flatten broad curls into a horizontal plateau.
            z = 1.112+.013*math.tanh((v[2]-1.112)/.013) if v[2]>1.112 else v[2]
            verts.append((v[0], v[1], z))
    verts.append(tuple(points[3]))
    tip = len(verts)-1
    faces = [tuple(range(sides-1, -1, -1))]
    faces += [(j*sides+k, j*sides+(k+1)%sides, (j+1)*sides+(k+1)%sides, (j+1)*sides+k)
              for j in range(sections-1) for k in range(sides)]
    faces += [((sections-1)*sides+k, (sections-1)*sides+(k+1)%sides, tip) for k in range(sides)]
    return verts, faces


def _scalp(character):
    """Continuous underlying mass, hidden by broad directional surface clumps."""
    count, levels = 40, 13
    verts = [(0., .014, 1.125)]
    for j in range(1, levels+1):
        for k in range(count):
            a = 2*math.pi*k/count
            front = max(0., -math.sin(a))
            back = max(0., math.sin(a))
            edge = 1.80-.42*front+.44*back
            if character == 'ravi': edge -= .15*front
            theta = edge*j/levels
            swell = 1+.022*math.sin(3*a+.4)+.012*math.sin(7*a-1.1)
            verts.append((.126*math.sin(theta)*math.cos(a)*swell,
                          .014+.106*math.sin(theta)*math.sin(a)*swell,
                          1.016+.109*math.cos(theta)))
    faces = [(0, 1+k, 1+(k+1)%count) for k in range(count)]
    for j in range(levels-1):
        low, high = 1+j*count, 1+(j+1)*count
        faces += [(low+k, high+k, high+(k+1)%count, low+(k+1)%count) for k in range(count)]
    # Hidden closure is head-weighted too; no open back or visible skin gaps.
    verts.append((0., .018, .995)); bottom = len(verts)-1
    faces += [(1+(levels-1)*count+k, bottom, 1+(levels-1)*count+(k+1)%count) for k in range(count)]
    return verts, faces


def build_hair(character, mesh_callback):
    """Build distinct, asymmetrical Boaz/Ravi hair using the existing palette/UVs.

    Return a geometry summary. No anatomy, accessory, rig or animation mutation.
    Clumps have explicit art-directed paths, rather than indexed circular rows.
    """
    if character not in ('boaz', 'ravi'):
        raise ValueError('Unknown hair character: '+str(character))
    meshes = []
    def emit(name, geometry, color):
        vertices, faces = geometry
        meshes.append(mesh_callback(name, vertices, faces, color, 'head'))
    emit('Hair_continuous_sculpted_mass', _scalp(character), 'Hair')
    # Four control points per curl: buried root, lifted shoulder, curved body, tip.
    # The unequal crown fan establishes one clear flow without a parting grid.
    locks = [
        ('crown_crest', ((-.042,.022,1.103),(-.045,-.006,1.124),(.002,-.015,1.124),(.038,-.010,1.113)), .027,.011, (0,-.2,1), 'HairLight', -.22),
        ('crown_left', ((-.017,.026,1.107),(-.061,.024,1.122),(-.085,.002,1.117),(-.100,-.022,1.089)), .031,.013, (-.4,0,1), 'Hair', .26),
        ('crown_right', ((-.015,.020,1.108),(.029,.049,1.125),(.077,.030,1.107),(.107,.014,1.083)), .033,.014, (.4,.1,1), 'Hair', -.18),
        ('crown_back', ((-.023,.013,1.111),(-.012,.065,1.118),(.035,.093,1.094),(.062,.103,1.071)), .033,.013, (0,.5,1), 'HairLight', .18),
        ('crown_back_left', ((-.025,.016,1.105),(-.065,.064,1.108),(-.092,.082,1.073),(-.111,.068,1.047)), .031,.013, (-.4,.5,.7), 'Hair', -.22),
        ('crown_back_right', ((.025,.032,1.103),(.076,.066,1.110),(.106,.072,1.076),(.131,.050,1.049)), .029,.013, (.6,.4,.7), 'Hair', .20),
    ]
    # Deliberately unequal pony: a dominant diagonal forelock and shorter companions.
    if character == 'boaz':
        locks += [
            ('fringe_sweep', ((.035,-.028,1.103),(.010,-.083,1.114),(-.040,-.108,1.064),(-.069,-.109,1.012)), .033,.013, (0,-1,.3), 'HairLight', -.25),
            ('fringe_center', ((.065,-.016,1.094),(.044,-.070,1.111),(.013,-.110,1.069),(-.009,-.113,1.027)), .027,.012, (0,-1,.25), 'Hair', .15),
            ('fringe_right', ((.080,-.003,1.084),(.088,-.057,1.102),(.065,-.092,1.057),(.051,-.104,1.028)), .025,.012, (.3,-1,.3), 'Hair', -.10),
            ('fringe_left', ((-.015,-.027,1.107),(-.054,-.060,1.110),(-.082,-.086,1.064),(-.105,-.078,1.035)), .029,.014, (-.3,-1,.3), 'Hair', .20),
            ('fringe_short', ((.012,-.020,1.113),(-.015,-.063,1.121),(-.031,-.090,1.093),(-.046,-.103,1.066)), .021,.010, (0,-1,.5), 'Hair', -.20),
        ]
    else:
        locks += [
            ('fringe_adventurer', ((-.036,-.014,1.108),(-.021,-.065,1.122),(.024,-.095,1.091),(.049,-.109,1.038)), .032,.013, (0,-1,.4), 'HairLight', .24),
            ('fringe_left', ((-.014,-.006,1.112),(-.064,-.050,1.119),(-.084,-.087,1.080),(-.107,-.089,1.044)), .030,.013, (-.3,-1,.4), 'Hair', -.22),
            ('fringe_center', ((-.022,-.023,1.112),(-.020,-.078,1.116),(-.034,-.101,1.080),(-.052,-.110,1.046)), .025,.012, (0,-1,.3), 'Hair', .16),
            ('fringe_right', ((.036,-.008,1.103),(.075,-.048,1.113),(.096,-.070,1.081),(.114,-.075,1.047)), .026,.013, (.4,-1,.4), 'Hair', -.21),
            ('front_cowlick', ((-.020,.002,1.110),(.013,-.024,1.125),(.048,-.034,1.122),(.069,-.043,1.106)), .024,.010, (0,-.4,1), 'HairLight', .2),
        ]
    # Side and nape gestures overlap diagonally, never forming horizontal rows.
    for sign, shift in [(-1, -.006), (1, .007)]:
        side = 'left' if sign < 0 else 'right'
        # Band is on the outside of Ravi's scalp. Upper clumps stop at its seam.
        endz = 1.041 if character == 'ravi' else 1.008
        locks.append((side+'_temple', ((sign*.083,-.023,1.082),(sign*.126,-.023,1.080),(sign*.133,-.035,1.044),(sign*.134,-.044,endz)), .024,.012, (sign,-.4,.3), 'Hair', sign*.22))
        locks.append((side+'_over_ear', ((sign*.098,.016,1.056),(sign*.138,.021,1.063),(sign*.146,.014,1.028),(sign*.148,.004,.990+shift)), .023,.010, (sign,.1,.2), 'HairLight' if sign<0 else 'Hair', sign*.2))
        locks.append((side+'_behind_ear', ((sign*.105,.045,1.030),(sign*.136,.060,1.025),(sign*.134,.058,.984),(sign*.118,.044,.961+shift)), .025,.012, (sign,.5,.2), 'Hair', sign*-.2))
        locks.append((side+'_rear_diagonal', ((sign*.057,.072,1.076),(sign*.106,.103,1.073),(sign*.119,.100,1.023),(sign*.111,.083,.978)), .030,.013, (sign*.5,1,.2), 'Hair', sign*.25))
    locks += [
        ('rear_center_sweep', ((.015,.073,1.084),(.040,.117,1.066),(.023,.127,1.025),(-.010,.120,.980)), .032,.012, (0,1,.2), 'Hair', -.20),
        ('rear_left_sweep', ((-.025,.069,1.085),(-.063,.105,1.067),(-.077,.122,1.024),(-.063,.110,.964)), .030,.013, (-.2,1,.2), 'HairLight', .15),
        ('rear_right_sweep', ((.050,.066,1.071),(.084,.106,1.040),(.074,.119,.992),(.050,.108,.951)), .028,.012, (.2,1,.2), 'Hair', -.25),
        ('nape_left', ((-.056,.095,1.011),(-.056,.125,.992),(-.040,.118,.967),(-.023,.101,.944)), .021,.010, (0,1,.1), 'Hair', .18),
        ('nape_right', ((.026,.104,1.006),(.028,.128,.982),(.015,.118,.962),(.012,.099,.938)), .023,.010, (0,1,.1), 'Hair', -.20),
        ('nape_outer_left', ((-.087,.069,1.003),(-.108,.096,.985),(-.094,.102,.964),(-.077,.084,.945)), .020,.010, (-.4,1,.1), 'Hair', -.2),
    ]
    for name, points, width, depth, normal, color, twist in locks:
        emit('Hair_'+character+'_'+name, clump_geometry(points, width, depth, _unit(normal), twist), color)
    return dict(character=character, clumps=len(locks), objects=meshes, max_rest_z=1.125)
